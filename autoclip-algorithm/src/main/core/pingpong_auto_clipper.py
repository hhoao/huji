import glob
import os
import shutil
from typing import Any, override
from xmlrpc.client import MAXINT

from src.main.config.config import (
    CommonAutoClipOptions,
    PingPongAutoClipOptions,
)
from src.main.constant.autoclip_constant import (
    ActionType,
    PingPongAutoClipConfig,
    SegmentInfo,
    ping_pong_classes_mapping,
    ping_pong_merge_fire_ball_and_play_ball_classes_mapping,
)
from src.main.constant.error_codes import ErrorCodes, ServiceError
from src.main.core.action_segment_detector import ActionSegmentDetector
from src.main.core.auto_clipper import AutoClipper, CleanableFileCollection
from src.main.core.ping_pong_action_segment_detector import PingPongActionSegmentDetector
from src.main.service.large_model_service import LargeModelService
from src.main.utils import path_utils
from src.main.utils.video_utils import (
    VideoInfo,
    clip_video_by_times,
)


os.environ["OPENCV_FFMPEG_CAPTURE_OPTIONS"] = "loglevel;error"


"""
目前最快（1h10min的视频)：
将视频转换为便于预测的格式(缩小大小) + 优化后的裁剪+ 优化后的合并
预测耗时: 77.13s
裁剪耗时：13s
合并耗时: 0.76s
总耗时: 522.18 s
"""


class PingPongAutoClipper(AutoClipper[PingPongAutoClipConfig]):
    def __init__(
        self,
        autoclip_service_config: PingPongAutoClipOptions,
        common_config: CommonAutoClipOptions,
        large_model_service: LargeModelService,
    ) -> None:
        super().__init__(common_config, large_model_service)
        self.singles_model: str = autoclip_service_config.singles_model
        self.threshold_count: int | None = autoclip_service_config.threshold_count

        self.default_autoclip_config: PingPongAutoClipConfig = PingPongAutoClipConfig(
            remove_replay=autoclip_service_config.is_ignore_playback,
            reserve_time_before_single_round=autoclip_service_config.reserve_header_seconds,
            reserve_time_after_single_round=autoclip_service_config.reserve_tail_seconds,
            fireball_max_seconds=autoclip_service_config.fireball_max_seconds,
            minimum_duration_single_round=autoclip_service_config.minimum_duration_single_round,
            minimum_duration_great_ball=autoclip_service_config.minimum_duration_great_ball,
        )

    @override
    def _format_config(self, custom_config: dict[str, Any] | None = None) -> PingPongAutoClipConfig:
        if custom_config is None:
            return PingPongAutoClipConfig(**self.default_autoclip_config.model_dump())
        merged_config = PingPongAutoClipConfig(**self.default_autoclip_config.model_dump())
        custom_config_dict = PingPongAutoClipConfig.model_validate(custom_config).model_dump(
            exclude_unset=True
        )
        for field_name, field_value in custom_config_dict.items():
            if field_value is not None:
                setattr(merged_config, field_name, field_value)
        return merged_config

    @override
    def _get_current_predict_model(self, clip_config: PingPongAutoClipConfig) -> str:
        return self.singles_model

    @override
    def _get_classes_mapping(self, clip_config: PingPongAutoClipConfig) -> dict[str, ActionType]:
        if clip_config.merge_fire_ball_and_play_ball:
            return ping_pong_merge_fire_ball_and_play_ball_classes_mapping
        return ping_pong_classes_mapping

    @override
    def _get_action_segment_detector(
        self, clip_config: PingPongAutoClipConfig, input_video_info: VideoInfo
    ) -> ActionSegmentDetector:
        is_ignore_playback: bool = (
            bool(clip_config.remove_replay) if clip_config.remove_replay is not None else False
        )
        merge_fire_ball_and_play_ball = (
            clip_config.merge_fire_ball_and_play_ball
            if clip_config.merge_fire_ball_and_play_ball is not None
            else True
        )
        return PingPongActionSegmentDetector(
            is_ignore_playback=is_ignore_playback,
            is_merge_fire_ball_and_play_ball=merge_fire_ball_and_play_ball,
        )

    @override
    def _clip_video(
        self,
        cleanable_file_collection: CleanableFileCollection,
        clip_config: PingPongAutoClipConfig,
        input_video_info: VideoInfo,
        match_segments: list[dict[ActionType, SegmentInfo]],
        all_ball_output_dir: str,
        great_ball_output_dir: str,
    ) -> tuple[list[str], list[str], list[dict[ActionType, SegmentInfo]]]:
        fireball_max_seconds = clip_config.fireball_max_seconds or 60
        reserve_tail_seconds = clip_config.reserve_time_after_single_round or 0
        reserve_header_seconds = clip_config.reserve_time_before_single_round or 0
        minimum_duration_single_round = clip_config.minimum_duration_single_round or 2
        minimum_duration_great_ball = clip_config.minimum_duration_great_ball or 10
        great_ball_editing = clip_config.great_ball_editing or False

        video_list: tuple[list[str], list[str], list[dict[ActionType, SegmentInfo]]]

        if clip_config.merge_fire_ball_and_play_ball:
            video_list = self._clip_videos_to_dir_without_fire_ball(
                video_info=input_video_info,
                video_path=input_video_info.video_path,
                valid_segment_list=match_segments,
                reserve_header_seconds=reserve_header_seconds,
                reserve_tail_seconds=reserve_tail_seconds,
                minimum_duration_single_round=minimum_duration_single_round,
                minimum_duration_great_ball=minimum_duration_great_ball,
                all_ball_output_dir=all_ball_output_dir,
                great_ball_output_dir=great_ball_output_dir,
                great_ball_editing=great_ball_editing,
                cleanable_file_collection=cleanable_file_collection,
            )
        else:
            video_list = self._clip_videos_to_dir(
                video_info=input_video_info,
                video_path=input_video_info.video_path,
                valid_segment_list=match_segments,
                fireball_max_seconds=fireball_max_seconds,
                reserve_header_seconds=reserve_header_seconds,
                reserve_tail_seconds=reserve_tail_seconds,
                minimum_duration_single_round=minimum_duration_single_round,
                minimum_duration_great_ball=minimum_duration_great_ball,
                all_ball_output_dir=all_ball_output_dir,
                great_ball_output_dir=great_ball_output_dir,
                great_ball_editing=great_ball_editing,
                cleanable_file_collection=cleanable_file_collection,
            )
        return video_list

    def _clip_videos_to_dir(
        self,
        video_info: VideoInfo,
        video_path: str,
        valid_segment_list: list[dict[ActionType, SegmentInfo]],
        fireball_max_seconds: float,
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
            fire_ball_start_seconds: float = segments[ActionType.FIRE_BALL].start_seconds
            fire_ball_end_seconds: float = segments[ActionType.FIRE_BALL].end_seconds

            play_ball_end_seconds: float = segments[ActionType.PLAY_BALL].end_seconds

            if fire_ball_end_seconds > play_ball_end_seconds:
                fire_ball_end_seconds = play_ball_end_seconds

            if ActionType.PICK_BALL in segments:
                pick_ball_end_seconds: float = segments[ActionType.PICK_BALL].end_seconds
            else:
                pick_ball_end_seconds = MAXINT

            start_seconds: float = max(
                max(
                    fire_ball_start_seconds - reserve_header_seconds,
                    0,
                ),
                last_end_seconds,
            )

            if fire_ball_end_seconds - start_seconds > fireball_max_seconds or 60:
                start_seconds = fire_ball_end_seconds - fireball_max_seconds

            if start_seconds - last_end_seconds < 0.5:
                start_seconds = start_seconds + 0.5

            end_seconds: float = min(
                pick_ball_end_seconds,
                play_ball_end_seconds + reserve_tail_seconds,
            )

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
