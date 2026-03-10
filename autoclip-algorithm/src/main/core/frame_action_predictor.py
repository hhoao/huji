import logging
import os
import tempfile
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Any

import cv2
from ray import remote
from tqdm import tqdm

from src.main.constant.autoclip_constant import (
    ActionType,
    PredictedFrameInfo,
    VideoInfo,
)
from src.main.pojo.video_clip_vo import VideoSegmentInfo
from src.main.service.large_model_service import ModelPredictor
from src.main.utils import video_utils


def convert_milliseconds(milliseconds: int, start_time: str = "00:00:00") -> str:
    """
    将毫秒时间戳转换为可读的时间格式

    参数:
        milliseconds: 毫秒时间戳
        start_time: 起始时间( 格式：HH:MM:SS 或 HH:MM:SS.mmm)

    返回:
        可读时间字符串(格式：HH:MM:SS.mmm)
    """
    start_parts: list[str] = start_time.split(":")
    if len(start_parts) == 3:
        h, m, s = start_parts
        if "." in s:
            s, ms = s.split(".")
            start_ms: int = int(h) * 3600 * 1000 + int(m) * 60 * 1000 + int(s) * 1000 + int(ms)
        else:
            start_ms = int(h) * 3600 * 1000 + int(m) * 60 * 1000 + int(s) * 1000
    else:
        raise ValueError(f"无效的起始时间格式: {start_time}，应为 HH:MM:SS 或 HH:MM:SS.mmm")

    total_ms: int = start_ms + milliseconds
    total_seconds: int = int(total_ms // 1000)
    milliseconds = total_ms % 1000
    hours, remainder = divmod(total_seconds, 3600)
    minutes, seconds = divmod(remainder, 60)

    return f"{hours:02d}:{minutes:02d}:{seconds:02d}.{milliseconds:03d}"


def init_pool_processes(the_processed_frames: Any):
    global processed_frames
    processed_frames = the_processed_frames


def extract_frames_v2(
    video_segment_info: VideoSegmentInfo,
    per_second_frames: int,
    model_predictor: ModelPredictor,
    class_mappings: dict[str, ActionType],
) -> list[PredictedFrameInfo]:
    results: list[PredictedFrameInfo] = []
    with tempfile.TemporaryDirectory() as temp_dir:
        video_utils.interval_extract_frames(
            video_path=video_segment_info.video_path,
            frame_interval=per_second_frames,
            temp_dir=temp_dir,
        )
        frames: list[str] = [str(path) for path in Path(temp_dir).rglob("*") if path.is_file()]
        frames.sort(key=lambda x: int(x.split("/")[-1].split(".")[0]))
        results = predict_frames(
            frames,
            per_second_frames,
            video_segment_info,
            model_predictor,
            class_mappings=class_mappings,
        )
    return results


def predict_frames(
    frames: list[str],
    per_second_frames: int,
    video_segment_info: VideoSegmentInfo,
    model_predictor: ModelPredictor,
    class_mappings: dict[str, ActionType],
) -> list[PredictedFrameInfo]:
    results: list[PredictedFrameInfo] = []
    current_second = video_segment_info.start_time

    for frame in frames:
        res = model_predictor.predict(frame, class_mappings)
        results.append(PredictedFrameInfo(action_type=res, seconds=current_second))
        current_second += 1 / per_second_frames
    return results


def extract_frames(
    video_path: str,
    start_frame: int,
    end_frame: int,
    frame_interval: int,
    model_predictor: ModelPredictor,
    classes_mapping: dict[str, ActionType],
) -> list[PredictedFrameInfo]:
    """
    工作进程函数：从指定范围的帧中提取图像

    参数:
        video_path: 视频文件路径
        output_dir: 输出图像目录
        start_frame: 开始帧索引（包含）
        end_frame: 结束帧索引（不包含）
        frame_interval: 帧间隔，每隔多少帧提取一帧
        processed_frames: 共享内存，用于记录已处理的帧数
    """
    cap: cv2.VideoCapture = cv2.VideoCapture(video_path)

    cap.set(cv2.CAP_PROP_POS_FRAMES, start_frame)
    cap.set(cv2.CAP_PROP_HW_ACCELERATION, cv2.VIDEO_ACCELERATION_ANY)

    extracted_count: int = 0
    predict_infos: list[PredictedFrameInfo] = []

    frame_range = range(start_frame, end_frame, frame_interval)

    with TemporaryDirectory() as temp_dir:
        for current_fps in tqdm(
            frame_range, desc=f"处理视频片段({start_frame}-{end_frame}帧率)", unit="帧", leave=False
        ):
            cap.set(cv2.CAP_PROP_POS_FRAMES, current_fps)
            if current_fps == start_frame:
                extracted_count += 1
            else:
                extracted_count += frame_interval
            if cap.get(cv2.CAP_PROP_POS_FRAMES) != current_fps:
                continue
            success: bool
            frame: Any
            success, frame = cap.read()
            if not success:
                logging.warning(f"在帧 {current_fps} 处读取失败，跳过此帧")
                continue

            video_name: str = Path(video_path).stem
            output_path: str = os.path.join(temp_dir, f"{video_name}_frame_{int(current_fps)}.jpg")

            msec: float = cap.get(cv2.CAP_PROP_POS_MSEC) if current_fps != 0 else 0
            success = cv2.imwrite(output_path, frame)

            if success:
                res: ActionType = model_predictor.predict(
                    output_path, classes_mapping=classes_mapping
                )
                predict_info: PredictedFrameInfo = PredictedFrameInfo(
                    action_type=res, seconds=msec / 1000
                )

                predict_infos.append(predict_info)
                # os.remove(output_path)
            else:
                logging.error(f"无法保存帧 {current_fps} 到 {output_path}")
        cap.release()

    logging.info(f"视频片段 [{start_frame}, {end_frame}帧] 处理完成")
    return predict_infos


@remote
def extract_frames_worker_distributed(
    video_data: bytes, model: bytes, class_mappings: dict[str, ActionType]
):
    with (
        tempfile.NamedTemporaryFile(suffix=".pt", delete=False) as model_file,
        tempfile.NamedTemporaryFile(suffix=".mp4", delete=False) as video_file,
    ):
        model_predictor = ModelPredictor(model_file.name, False)
        model_file.write(model)  # pyright: ignore [reportUnknownArgumentType]
        video_file.write(video_data)  # pyright: ignore [reportUnknownArgumentType]
        video_info: VideoInfo = video_utils.get_video_info(video_file.name)
        predict_infos: list[PredictedFrameInfo] = extract_frames_v2(
            video_segment_info=VideoSegmentInfo(
                video_path=video_file.name, start_time=0, end_time=video_info.duration
            ),
            per_second_frames=5,
            model_predictor=model_predictor,
            class_mappings=class_mappings,
        )
        return predict_infos
