from typing import Any, override

from src.main.config.config import BadmintonAutoClipOptions, CommonAutoClipOptions
from src.main.constant.autoclip_constant import (
    ActionType,
    BadmintonAutoClipConfig,
    MatchType,
    SegmentInfo,
    VideoInfo,
    badminton_classes_mapping,
)
from src.main.core.action_segment_detector import ActionSegmentDetector
from src.main.core.auto_clipper import AutoClipper, CleanableFileCollection
from src.main.core.badminton_action_segment_detector import BadmintonActionSegmentDetector
from src.main.service.large_model_service import LargeModelService


class BadmintonAutoClipper(AutoClipper[BadmintonAutoClipConfig]):
    def __init__(
        self,
        autoclip_service_config: BadmintonAutoClipOptions,
        common_config: CommonAutoClipOptions,
        large_model_service: LargeModelService,
    ) -> None:
        super().__init__(common_config, large_model_service)
        self.singles_model = autoclip_service_config.singles_model
        self.doubles_model = autoclip_service_config.doubles_model
        self.threshold_count: int | None = autoclip_service_config.threshold_count

        self.default_autoclip_config = BadmintonAutoClipConfig(
            mode=autoclip_service_config.mode,
            match_type=autoclip_service_config.match_type,
            great_ball_editing=autoclip_service_config.great_ball_editing,
            remove_replay=autoclip_service_config.is_ignore_playback,
            reserve_time_before_single_round=autoclip_service_config.reserve_header_seconds,
            reserve_time_after_single_round=autoclip_service_config.reserve_tail_seconds,
            minimum_duration_single_round=autoclip_service_config.minimum_duration_single_round,
            minimum_duration_great_ball=autoclip_service_config.minimum_duration_great_ball,
        )

    @override
    def _get_classes_mapping(self, clip_config: BadmintonAutoClipConfig) -> dict[str, ActionType]:
        return badminton_classes_mapping

    @override
    def _clip_video(
        self,
        cleanable_file_collection: CleanableFileCollection,
        clip_config: BadmintonAutoClipConfig,
        input_video_info: VideoInfo,
        match_segments: list[dict[ActionType, SegmentInfo]],
        all_ball_output_dir: str,
        great_ball_output_dir: str,
    ) -> tuple[list[str], list[str], list[dict[ActionType, SegmentInfo]]]:
        reserve_header_seconds = clip_config.reserve_time_before_single_round or 0
        reserve_time_after_single_round = clip_config.reserve_time_after_single_round or 0
        minimum_duration_single_round = clip_config.minimum_duration_single_round or 2
        minimum_duration_great_ball = clip_config.minimum_duration_great_ball or 10
        great_ball_editing = clip_config.great_ball_editing or False
        video_list: tuple[list[str], list[str], list[dict[ActionType, SegmentInfo]]] = (
            self._clip_videos_to_dir_without_fire_ball(
                video_info=input_video_info,
                video_path=input_video_info.video_path,
                valid_segment_list=match_segments,
                reserve_header_seconds=reserve_header_seconds,
                reserve_tail_seconds=reserve_time_after_single_round,
                minimum_duration_single_round=minimum_duration_single_round,
                minimum_duration_great_ball=minimum_duration_great_ball,
                all_ball_output_dir=all_ball_output_dir,
                great_ball_output_dir=great_ball_output_dir,
                great_ball_editing=great_ball_editing,
                cleanable_file_collection=cleanable_file_collection,
            )
        )
        return video_list

    @override
    def _format_config(
        self, custom_config: dict[str, Any] | None = None
    ) -> BadmintonAutoClipConfig:
        if custom_config is None:
            return BadmintonAutoClipConfig(**self.default_autoclip_config.model_dump())
        merged_config = BadmintonAutoClipConfig(**self.default_autoclip_config.model_dump())
        custom_config_dict = BadmintonAutoClipConfig.model_validate(custom_config).model_dump(
            exclude_unset=True
        )
        for field_name, field_value in custom_config_dict.items():
            if field_value is not None:
                setattr(merged_config, field_name, field_value)
        return merged_config

    @override
    def _get_current_predict_model(self, clip_config: BadmintonAutoClipConfig) -> str:
        if clip_config.match_type == MatchType.SINGLES_MATCH:
            return self.singles_model
        return self.doubles_model

    @override
    def _get_action_segment_detector(
        self, clip_config: BadmintonAutoClipConfig, input_video_info: VideoInfo
    ) -> ActionSegmentDetector:
        is_ignore_playback: bool = (
            bool(clip_config.remove_replay) if clip_config.remove_replay is not None else False
        )
        return BadmintonActionSegmentDetector(
            is_ignore_playback=is_ignore_playback,
        )
