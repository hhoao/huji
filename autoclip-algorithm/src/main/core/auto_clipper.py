import abc
import glob
import json
import math
import os
import shutil
import tempfile
import time
from concurrent.futures import Future, ProcessPoolExecutor
from multiprocessing import Value
from pathlib import Path
from threading import Thread
from typing import Any, cast

import cv2
import ray
from tqdm import tqdm

import src
from src.main.config.config import CommonAutoClipOptions
from src.main.constant.autoclip_constant import (
    ActionType,
    PredictedFrameInfo,
    SegmentInfo,
    VideoBaseInfo,
    VideoClipOutputInfo,
    VideoInfo,
)
from src.main.constant.error_codes import ErrorCodes, ServiceError
from src.main.constant.progress_constant import ActionProgressProportion, VideoProcessState
from src.main.core import frame_action_predictor
from src.main.core.action_segment_detector import ActionSegmentDetector
from src.main.core.frame_action_predictor import extract_frames, init_pool_processes
from src.main.logger import LOG
from src.main.pojo.video_clip_vo import VideoSegmentInfo
from src.main.service.large_model_service import LargeModelService, ModelPredictor
from src.main.service.progress_handler import ProgressHandler
from src.main.utils import path_utils, video_utils
from src.main.utils.common_util import timer
from src.main.utils.video_utils import (
    clip_video_by_times,
    get_video_base_info,
    get_video_info,
    merge_videos_by_ffmpeg,
    resize_video_ratio,
)


class CleanableFileCollection:
    def __init__(self) -> None:
        self.file_list: list[str] = []

    def add_file(self, file_path: str) -> None:
        self.file_list.append(file_path)

    def clean(self) -> None:
        for file_path in self.file_list:
            if os.path.exists(file_path):
                os.remove(file_path)
        self.file_list.clear()


class AutoClipper[C](abc.ABC):
    def __init__(
        self,
        common_auto_clip_options: CommonAutoClipOptions,
        large_model_service: LargeModelService,
    ):
        self.cache_path = common_auto_clip_options.cache_path
        self.output_dir = common_auto_clip_options.output_dir
        self.frame_interval = common_auto_clip_options.frame_interval
        self.workers = common_auto_clip_options.workers
        self.split_count = common_auto_clip_options.split_count
        self.large_model_service = large_model_service
        self.debug_clip_frame_output_dir = common_auto_clip_options.debug_clip_frame_output_dir
        self.clipped_output_dir = Path(common_auto_clip_options.output_dir) / "clipped"
        self.resized_output_dir = Path(common_auto_clip_options.output_dir) / "resized"
        self.clipped_output_dir.mkdir(parents=True, exist_ok=True)
        self.resized_output_dir.mkdir(parents=True, exist_ok=True)

    @abc.abstractmethod
    def _clip_video(
        self,
        cleanable_file_collection: CleanableFileCollection,
        clip_config: C,
        input_video_info: VideoInfo,
        match_segments: list[dict[ActionType, SegmentInfo]],
        all_ball_output_dir: str,
        great_ball_output_dir: str,
    ) -> tuple[list[str], list[str], list[dict[ActionType, SegmentInfo]]]:
        pass

    @abc.abstractmethod
    def _format_config(self, custom_config: dict[str, Any] | None = None) -> C:
        pass

    @abc.abstractmethod
    def _get_current_predict_model(self, clip_config: C) -> str:
        pass

    @abc.abstractmethod
    def _get_action_segment_detector(
        self, clip_config: C, input_video_info: VideoInfo
    ) -> ActionSegmentDetector:
        pass

    @abc.abstractmethod
    def _get_classes_mapping(
        self,
        clip_config: C,
    ) -> dict[str, ActionType]:
        pass

    def _convert_action_point_to_match_segments(
        self,
        clip_config: C,
        prediction_actions_points: list[PredictedFrameInfo],
        input_video_info: VideoInfo,
    ) -> tuple[list[dict[ActionType, SegmentInfo]], list[SegmentInfo]]:
        action_segment_detector = self._get_action_segment_detector(clip_config, input_video_info)
        segments: tuple[list[dict[ActionType, SegmentInfo]], list[SegmentInfo]] = (
            action_segment_detector.convert_action_point_to_game_segments(prediction_actions_points)
        )
        return segments

    def predict_video_action_points_internal_distributed(
        self,
        video_path: str,
        model_name: str,
        segment_duration: float,
        class_mappings: dict[str, ActionType],
    ) -> list[PredictedFrameInfo]:
        ray.init(  # type: ignore
            address="ray://localhost:10001",
            runtime_env={"py_modules": [src], "excludes": ["resources"]},
        )

        video_info = video_utils.get_video_info(video_path)
        # 读取整个视频文件到内存
        duration = video_info.duration
        current_time = 0
        video_segment_data_refs: list[Any] = []

        while current_time < duration:
            next_time = min(current_time + segment_duration, duration)
            with tempfile.NamedTemporaryFile(suffix=".mp4", delete=False) as temp_file:
                video_utils.clip_video_by_times(
                    video_path,
                    current_time,
                    next_time - current_time,
                    output_file=str(temp_file.name),
                )
                video_segment_data_refs.append(ray.put(temp_file.read()))  # pyright: ignore [reportUnknownMemberType]
                current_time += segment_duration

        model_path = self.large_model_service.get_model_path(model_name)
        model_ref = ray.put(Path(model_path).read_bytes())  # type: ignore

        # 创建分布式任务
        futures = []

        for video_segment_data_ref in video_segment_data_refs:
            future = frame_action_predictor.extract_frames_worker_distributed.options(  # type: ignore
                num_cpus=1, memory=1000 * 1024 * 1024, num_gpus=1
            ).remote(  # pyright: ignore [reportUnknownMemberType]
                video_segment_data_ref,
                model_ref,  # type: ignore
                class_mappings,
            )
            futures.append(future)  # type: ignore

        result: list[list[PredictedFrameInfo]] = cast(
            list[list[PredictedFrameInfo]],
            ray.get(futures),  # type: ignore
        )

        all_predict_infos: list[PredictedFrameInfo] = []

        for segment_predictions in result:  # type: ignore
            all_predict_infos.extend(segment_predictions)

        all_predict_infos.sort(key=lambda x: x.seconds)

        LOG.info(f"分布式处理完成，总共找到 {len(all_predict_infos)} 个动作点")

        self._cache_predict_infos(all_predict_infos, video_path)

        return all_predict_infos

    def predict_video_action_points_internal_v2(
        self,
        video_path: str,
        model_name: str,
        class_mappings: dict[str, ActionType],
        segment_duration: int = 120,
        workers: int | None = None,
        per_second_frames: int = 6,
        progress_handler: ProgressHandler | None = None,
    ) -> list[PredictedFrameInfo]:
        """
        预测优化：
        视频信息：
        时长：16分钟
        优化后方案时长：
        * opencv每获取一个帧率后立马预测耗时: 396.64 秒。
        * ffmpeg先获取所有帧率然后预测耗时：115秒
        * ffmpeg gpu获取所有帧率耗时：30s !!!
        * 单线程预测已截取的帧率耗时：90s !!!
        * 并发预测已经截取的帧率耗时：26.18 秒 !!!
        * 并发(获取帧率+ 预测)耗时： 69.53 秒。!!!
        * 速度提高5倍!!!!
        """
        with tempfile.TemporaryDirectory() as temp_dir:
            video_info = video_utils.get_video_info(video_path)
            video_segment_infos: list[VideoSegmentInfo] = []
            duration = video_info.duration
            current_time = 0

            while current_time < duration:
                next_time = min(current_time + segment_duration, duration)
                output_file = str(Path(temp_dir, f"{current_time}-{next_time}.mp4"))
                video_utils.clip_video_by_times(
                    video_path,
                    current_time,
                    segment_duration,
                    output_file=output_file,
                )
                video_segment_infos.append(
                    VideoSegmentInfo(
                        video_path=output_file, start_time=current_time, end_time=next_time
                    )
                )
                current_time += segment_duration

            futures: list[Future[list[PredictedFrameInfo]]] = []

            if workers is None:
                cpu_count = os.cpu_count()
                workers = int(cpu_count / 2) if cpu_count else 8

            model_predictor: ModelPredictor = self.large_model_service.get_predictor(model_name)
            with ProcessPoolExecutor(
                max_workers=workers,
            ) as pool:
                for video_segment_info in video_segment_infos:
                    future = pool.submit(
                        frame_action_predictor.extract_frames_v2,
                        video_segment_info,
                        per_second_frames,
                        model_predictor=model_predictor,
                        class_mappings=class_mappings,
                    )
                    futures.append(future)

            results: list[PredictedFrameInfo] = []
            for future in futures:
                result = future.result()
                results.extend(result)
                if progress_handler is not None:
                    progress_handler.add_multiple_progress(
                        duration,
                        result[-1].seconds - result[0].seconds,
                        ActionProgressProportion.PREDICT_VIDEO_ACTION_POINTS,
                        VideoProcessState.PROCESSING,
                    )
            results.sort(key=lambda x: x.seconds)

            LOG.info(f"处理完成，总共找到 {len(results)} 个动作点")

            self._cache_predict_infos(results, video_path)

            return results

    def predict_video_action_points_internal(
        self,
        video_path: str,
        model_name: str,
        class_mappings: dict[str, ActionType],
        cframe_interval: int | None = None,
        workers: int | None = None,
        split_count: int | None = None,
        progress_handler: ProgressHandler | None = None,
    ) -> list[PredictedFrameInfo]:
        cap: cv2.VideoCapture = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            raise ValueError(f"无法打开视频文件: {video_path}")

        frame_count: int = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        fps: float = cap.get(cv2.CAP_PROP_FPS)
        duration: float = frame_count / fps if fps and fps > 0 else 0
        frames_per_chunk: int = math.ceil(frame_count / (split_count or 1))

        cap.release()

        LOG.info(f"开始处理视频: {video_path}")
        LOG.info(f"视频信息: FPS={fps}, 总帧数={frame_count}, 时长={duration:.2f}秒")
        LOG.info(f"将使用 {workers} 个进程处理 {frames_per_chunk} 个视频片段")

        frame_interval: int = (
            cframe_interval if cframe_interval is not None else int(fps / 6) if fps else 1
        )

        # 创建共享内存用于记录已处理的时长
        processed_frames = Value("i", 0)
        running = Value("b", True)

        all_predict_infos: list[PredictedFrameInfo] = []

        if progress_handler is not None:
            Thread(
                target=self._start_update_progress,
                args=(duration, processed_frames, running, progress_handler),
            ).start()

        tqdm_bar = tqdm(
            total=frames_per_chunk,
            desc="处理视频帧",
            unit="帧",
            leave=False,
        )

        futures: list[Future[list[PredictedFrameInfo]]] = []

        model_predictor: ModelPredictor = self.large_model_service.get_predictor(model_name)

        with ProcessPoolExecutor(
            max_workers=int((workers or 2) / 2),
            initializer=init_pool_processes,
            initargs=(processed_frames,),
        ) as pool:
            for i in range(frames_per_chunk):
                start: int = i * (split_count or 1)
                end: int = min(start + (split_count or 1), frame_count)
                future = pool.submit(
                    extract_frames,
                    video_path,
                    start,
                    end,
                    frame_interval,
                    model_predictor,
                    classes_mapping=class_mappings,
                )
                futures.append(future)

        for future in futures:
            result = future.result()
            all_predict_infos.extend(future.result())
            processed_frames.value += result[-1].seconds - result[0].seconds
            tqdm_bar.update(1)

        pool.shutdown(wait=True)
        running.value = False
        tqdm_bar.close()
        self._cache_predict_infos(all_predict_infos, video_path)

        return all_predict_infos

    def _load_cache(self, video_path: str) -> list[PredictedFrameInfo] | None:
        video_name: str = Path(video_path).stem
        cache_path: str = path_utils.path_join(self.cache_path, f"{video_name}.json")
        if Path(cache_path).exists():
            with Path(cache_path).open() as f:
                infos_json: Any = json.load(f)
                predicted_frame_infos: list[PredictedFrameInfo] = [
                    PredictedFrameInfo(**info) for info in infos_json
                ]
                return predicted_frame_infos
        return None

    def _cache_predict_infos(
        self, all_predict_infos: list[PredictedFrameInfo], video_path: str
    ) -> str:
        Path(self.cache_path).mkdir(parents=True, exist_ok=True)
        video_name: str = Path(video_path).stem
        cache_path: str = path_utils.path_join(self.cache_path, f"{video_name}.json")
        with Path(cache_path).open("w") as f:
            json.dump(
                [info.__dict__ for info in all_predict_infos],
                f,
                indent=4,
                default=lambda o: o.__dict__,
            )
        return cache_path

    def _predict_video_action_points(
        self,
        cleanable_file_collection: CleanableFileCollection,
        video_info: VideoInfo,
        model_name: str,
        class_mappings: dict[str, ActionType],
        frame_interval: int | None = None,
        workers: int | None = None,
        split_count: int | None = None,
        progress_handler: ProgressHandler | None = None,
    ) -> list[PredictedFrameInfo]:
        video_path = video_info.video_path

        output_file = str(self.resized_output_dir / f"{Path(video_path).stem}.mp4")
        Path(output_file).parent.mkdir(parents=True, exist_ok=True)

        cache: list[PredictedFrameInfo] | None = self._load_cache(output_file)
        cleanable_file_collection.add_file(output_file)
        if cache is not None:
            return cache

        with timer("调整视频大小为适用于预测的分辨率"):
            resize_video_ratio(video_path, output_file, 640)
        if progress_handler is not None:
            progress_handler.add_progress_proportion(
                ActionProgressProportion.RESIZE_VIDEO, VideoProcessState.PROCESSING
            )
        return self.predict_video_action_points_internal_v2(
            video_path=output_file,
            model_name=model_name,
            segment_duration=120,
            class_mappings=class_mappings,
            workers=workers,
            per_second_frames=6,
            progress_handler=progress_handler,
        )

        # return self.predict_video_action_points_internal(
        #     output_file,
        #     model_name,
        #     frame_interval,
        #     workers,
        #     split_count,
        #     progress_handler,
        # )

    def _start_update_progress(
        self,
        duration: int,
        processed_frames: Any,
        running: Any,
        progress_handler: ProgressHandler,
    ):
        """
        更新进度条件：
        1. 已预测的帧数达到十分之一以上
        2. 距离上一次更新进度的时间间隔大于10秒
        创建一个共享内存, 这个共享内存用于存放已经预测的视频帧率数量，
        每个进程处理完一部分帧数量后就将数值添加到共享内存
        """
        duration_per_progress = duration // 10
        last_time = time.time()
        stop = False

        last_processed_frames = 0
        while not stop:
            # 计算当前应该达到的进度段
            expected_segment = processed_frames.value - last_processed_frames
            if stop or expected_segment > duration_per_progress or time.time() - last_time > 10:
                progress_handler.add_multiple_progress(
                    duration,
                    expected_segment,
                    ActionProgressProportion.PREDICT_VIDEO_ACTION_POINTS,
                    VideoProcessState.PROCESSING,
                )
                last_processed_frames = processed_frames.value
                last_time = time.time()
            if not running.value:
                if stop:
                    break
                stop = True
            time.sleep(1)

    def handle_video(
        self,
        input_video_info: VideoInfo,
        clip_config: C,
        cleanable_file_collection: CleanableFileCollection,
        progress_handler: ProgressHandler | None = None,
    ) -> VideoClipOutputInfo:
        classes_mapping = self._get_classes_mapping(clip_config)
        with timer("预测视频帧"):
            prediction_actions_points: list[PredictedFrameInfo] = self._predict_video_action_points(
                cleanable_file_collection,
                input_video_info,
                self._get_current_predict_model(clip_config),
                classes_mapping,
                self.frame_interval,
                self.workers,
                self.split_count,
                progress_handler,
            )

        segments: tuple[list[dict[ActionType, SegmentInfo]], list[SegmentInfo]] = (
            self._convert_action_point_to_match_segments(
                clip_config, prediction_actions_points, input_video_info
            )
        )

        match_segments: list[dict[ActionType, SegmentInfo]] = segments[0]

        with tempfile.TemporaryDirectory() as temp_dir:
            if (
                self.debug_clip_frame_output_dir is not None
                and len(self.debug_clip_frame_output_dir) > 0
            ):
                output_dir: Path = Path(
                    self.debug_clip_frame_output_dir, input_video_info.video_file.name
                )
                output_dir.mkdir(parents=True, exist_ok=True)
                output_dir_str = str(output_dir)
            else:
                output_dir_str = temp_dir

            with timer("裁剪视频"):
                all_ball_output_dir = path_utils.path_join(output_dir_str, "all")
                great_ball_output_dir = path_utils.path_join(output_dir_str, "greats")
                Path(all_ball_output_dir).mkdir(parents=True, exist_ok=True)
                Path(great_ball_output_dir).mkdir(parents=True, exist_ok=True)
                video_list = self._clip_video(
                    cleanable_file_collection,
                    clip_config,
                    input_video_info,
                    match_segments,
                    all_ball_output_dir,
                    great_ball_output_dir,
                )

                all_ball_video_list: list[str] = video_list[0]
                great_ball_video_list: list[str] = video_list[1]
                great_match_segments: list[dict[ActionType, SegmentInfo]] = video_list[2]

            output_merged_video_path: str = str(
                self.clipped_output_dir / input_video_info.video_path.split("/")[-1]
            )
            Path(output_merged_video_path).parent.mkdir(parents=True, exist_ok=True)

            cleanable_file_collection.add_file(output_merged_video_path)

            all_ball_video_list.sort(key=lambda x: int(x.split("/")[-1].split(".")[0]))
            with timer("合并视频"):
                merge_videos_by_ffmpeg(
                    all_ball_video_list,
                    output_merged_video_path,
                    input_video_info.codec_name,
                    input_video_info.bit_rate,
                )

            output_video_info: VideoBaseInfo = get_video_base_info(output_merged_video_path)

            great_match_video_info = [
                get_video_base_info(great_match_video)
                for great_match_video in great_ball_video_list
            ]

            video_output_info = VideoClipOutputInfo(
                all_match_merged_video_path=output_merged_video_path,
                all_match_merged_video_info=output_video_info,
                great_match_video_info=great_match_video_info,
                input_video_info=input_video_info,
                all_match_segments=match_segments,
                great_match_segments=great_match_segments,
                great_match_video_path_list=great_ball_video_list,
            )

            if progress_handler is not None:
                progress_handler.add_progress_proportion(
                    ActionProgressProportion.MERGE_AND_CLIP_VIDEO, VideoProcessState.PROCESSING
                )

            return video_output_info

    def autoclip_video(
        self,
        input_video_path: str,
        auto_clip_config: dict[str, Any] | None = None,
        progress_handler: ProgressHandler | None = None,
        cleanable_file_collection: CleanableFileCollection | None = None,
    ) -> VideoClipOutputInfo:
        if cleanable_file_collection is None:
            cleanable_file_collection = CleanableFileCollection()
        clip_config = self._format_config(auto_clip_config)

        input_video_info: VideoInfo = get_video_info(input_video_path)
        LOG.info(f"视频信息: {input_video_info}")
        LOG.info(f"视频剪辑配置: {clip_config}")

        with timer("处理视频"):
            video_clip_output_info: VideoClipOutputInfo = self.handle_video(
                input_video_info, clip_config, cleanable_file_collection, progress_handler
            )

        LOG.info(f"视频剪辑完成: {video_clip_output_info}")
        return video_clip_output_info

    def _clip_videos_to_dir_without_fire_ball(
        self,
        video_info: VideoInfo,
        video_path: str,
        valid_segment_list: list[dict[ActionType, SegmentInfo]],
        reserve_header_seconds: float,
        reserve_tail_seconds: float,
        minimum_duration_single_round: float,
        minimum_duration_great_ball: float,
        all_ball_output_dir: str,
        great_ball_output_dir: str,
        great_ball_editing: bool,
        cleanable_file_collection: CleanableFileCollection,
    ) -> tuple[list[str], list[str], list[dict[ActionType, SegmentInfo]]]:
        last_end_seconds: float = 0
        great_match_segments: list[dict[ActionType, SegmentInfo]] = []

        for s, segments in enumerate(valid_segment_list):
            play_ball_start_seconds: float = segments[ActionType.PLAY_BALL].start_seconds
            play_ball_end_seconds: float = segments[ActionType.PLAY_BALL].end_seconds

            start_seconds: float = max(
                max(
                    play_ball_start_seconds - reserve_header_seconds,
                    0.0,
                ),
                last_end_seconds,
            )

            if start_seconds - last_end_seconds < 0.5:
                start_seconds = start_seconds + 0.5

            end_seconds: float = play_ball_end_seconds + reserve_tail_seconds

            if end_seconds < last_end_seconds:
                continue

            duration: float = end_seconds - start_seconds

            if duration >= minimum_duration_single_round:
                all_ball_output_path = path_utils.path_join(all_ball_output_dir, f"{s}.mp4")
                great_ball_output_path = path_utils.path_join(great_ball_output_dir, f"{s}.mp4")

                clip_video_by_times(
                    input_file=video_path,
                    start_time=start_seconds,
                    duration=duration,
                    output_file=all_ball_output_path,
                )
                cleanable_file_collection.add_file(all_ball_output_path)

                if great_ball_editing and duration >= minimum_duration_great_ball:
                    shutil.copy(all_ball_output_path, great_ball_output_path)
                    cleanable_file_collection.add_file(great_ball_output_path)
                    great_match_segments.append(segments)

            last_end_seconds = end_seconds

        all_ball_video_list: list[str] = glob.glob(
            path_utils.path_join(all_ball_output_dir, "*.mp4")
        )
        great_ball_video_list: list[str] = glob.glob(
            path_utils.path_join(great_ball_output_dir, "*.mp4")
        )

        if len(all_ball_video_list) == 0:
            raise ServiceError(ErrorCodes.NO_VALID_SEGMENT)

        return all_ball_video_list, great_ball_video_list, great_match_segments
