from typing import override

from src.main.constant.autoclip_constant import (
    ActionType,
    PredictedFrameInfo,
    SegmentDetectorConfig,
    SegmentInfo,
)
from src.main.core.action_segment_detector import ActionSegmentDetector


class BadmintonActionSegmentDetector(ActionSegmentDetector):
    def __init__(
        self,
        is_ignore_playback: bool,
        segment_detect_config: dict[ActionType, SegmentDetectorConfig] = {},
    ):
        super().__init__()
        self.is_ignore_playback = is_ignore_playback
        self.segment_detect_config = segment_detect_config

    def _pre_process(
        self, action_points: list[PredictedFrameInfo], is_ignore_playback: bool
    ) -> list[PredictedFrameInfo]:
        return action_points

    def _get_segment_detector_config(
        self, action_type: ActionType, default_segment_detector_config: SegmentDetectorConfig
    ) -> SegmentDetectorConfig:
        segment_detect_config = self.segment_detect_config.get(action_type)
        if segment_detect_config is None:
            segment_detect_config = default_segment_detector_config
        return segment_detect_config

    @override
    def convert_action_point_to_game_segments(
        self, action_points: list[PredictedFrameInfo]
    ) -> tuple[list[dict[ActionType, SegmentInfo]], list[SegmentInfo]]:
        final_action_points: list[PredictedFrameInfo] = self._pre_process(
            action_points, is_ignore_playback=self.is_ignore_playback
        )

        segment_detect_config = self._get_segment_detector_config(
            ActionType.PICK_BALL, SegmentDetectorConfig(2.0, 6)
        )

        play_segments: list[SegmentInfo] = self._detect_continuous_classifier(
            final_action_points,
            ActionType.PLAY_BALL,
            interval_seconds=segment_detect_config.interval_seconds,
            window_count=segment_detect_config.window_count,
        )

        all_segments: list[SegmentInfo] = play_segments
        match_segments_list: list[dict[ActionType, SegmentInfo]] = (
            self._filter_match_segments_without_fire_ball(all_segments)
        )

        return match_segments_list, play_segments
