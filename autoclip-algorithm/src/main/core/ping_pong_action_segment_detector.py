from typing import override

from src.main.constant.autoclip_constant import (
    ActionType,
    PredictedFrameInfo,
    SegmentDetectorConfig,
    SegmentInfo,
)
from src.main.core.action_segment_detector import ActionSegmentDetector


class PingPongActionSegmentDetector(ActionSegmentDetector):
    def __init__(
        self,
        is_ignore_playback: bool,
        is_merge_fire_ball_and_play_ball: bool,
        segment_detect_config: dict[ActionType, SegmentDetectorConfig] = {},
    ):
        super().__init__()
        self.is_merge_fire_ball_and_play_ball = is_merge_fire_ball_and_play_ball
        self.is_ignore_playback = is_ignore_playback
        self.segment_detect_config = segment_detect_config

    def _get_playback_segments(
        self, sorted_action_point: list[PredictedFrameInfo]
    ) -> list[SegmentInfo]:
        """
        获取有效的playback回放片段

        规则：
        - 如果当前transition片段的上一个片段为pick_ball片段，且下一个片段为play_ball或者
        fire_ball片段，那么它为transition开始片段
        - 如果当前transition片段的上一个片段为play_ball或者pick_ball片段，且下一个片段为
        fire_ball或者pick_ball片段，那么它为transition结束片段
        - 因为 pick_ball -> fire_ball都既可能是开始片段也可能是结束片段, 所以规定如果出现
        此情况，如果判断上一个片段为开始片段，则当前片段为结束片段
        - 一对开始片段和结束片段即为有效的playback回放片段，该回放片段之间没有其他的
        transition片段
        """
        # 首先检测所有的transition片段
        transition_segments: list[SegmentInfo] = self._detect_continuous_classifier(
            sorted_action_point, ActionType.TRANSITION, interval_seconds=1.0, window_count=3
        )

        if not transition_segments:
            return []

        # 获取所有非transition的片段，用于判断transition片段的前后关系
        non_transition_segments: list[SegmentInfo] = []
        for action_type in [ActionType.PICK_BALL, ActionType.PLAY_BALL, ActionType.FIRE_BALL]:
            segments = self._detect_continuous_classifier(
                sorted_action_point, action_type, interval_seconds=1.0, window_count=3
            )
            non_transition_segments.extend(segments)

        # 按时间排序所有片段
        all_segments: list[SegmentInfo] = sorted(
            transition_segments + non_transition_segments, key=lambda x: x.start_seconds
        )

        # 标记transition片段的类型（开始或结束）
        transition_markers: list[tuple[str, SegmentInfo]] = []

        for i, segment in enumerate(all_segments):
            if segment.action_type == ActionType.TRANSITION:
                # 查找前一个非transition片段
                prev_segment: SegmentInfo | None = None
                for j in range(i - 1, -1, -1):
                    if all_segments[j].action_type != ActionType.TRANSITION:
                        prev_segment = all_segments[j]
                        break

                # 查找后一个非transition片段
                next_segment: SegmentInfo | None = None
                for j in range(i + 1, len(all_segments)):
                    if all_segments[j].action_type != ActionType.TRANSITION:
                        next_segment = all_segments[j]
                        break

                if (
                    prev_segment
                    and prev_segment.action_type == ActionType.PICK_BALL
                    and next_segment
                    and next_segment.action_type == ActionType.FIRE_BALL
                    and len(transition_markers) > 0
                    and transition_markers[-1][0] == "start"
                ):
                    transition_markers.append(("end", segment))
                elif (
                    prev_segment
                    and prev_segment.action_type == ActionType.PICK_BALL
                    and next_segment
                    and next_segment.action_type in [ActionType.PLAY_BALL, ActionType.FIRE_BALL]
                ):
                    transition_markers.append(("start", segment))
                # 判断是否为结束片段
                elif (
                    prev_segment
                    and (
                        prev_segment.action_type == ActionType.PLAY_BALL
                        or prev_segment.action_type == ActionType.PICK_BALL
                    )
                    and next_segment
                    and next_segment.action_type in [ActionType.FIRE_BALL, ActionType.PICK_BALL]
                ):
                    transition_markers.append(("end", segment))

        # 配对开始和结束片段，形成有效的playback片段
        playback_segments: list[SegmentInfo] = []
        start_segment: SegmentInfo | None = None

        for marker_type, segment in transition_markers:
            if marker_type == "start":
                start_segment = segment
            elif marker_type == "end" and start_segment is not None:
                # 检查开始和结束片段之间是否有其他transition片段
                has_intermediate_transition: bool = False
                for ts in transition_segments:
                    if start_segment.end_seconds < ts.start_seconds < segment.start_seconds:
                        has_intermediate_transition = True
                        break

                # 如果没有中间的transition片段，则形成有效的playback片段
                if not has_intermediate_transition:
                    playback_segment = SegmentInfo(
                        action_type=ActionType.PLAYBACK,
                        start_seconds=start_segment.start_seconds,
                        end_seconds=segment.end_seconds,
                    )
                    playback_segments.append(playback_segment)

                start_segment = None  # 重置开始片段

        return playback_segments

    def _remove_playback_segments(
        self, action_points: list[PredictedFrameInfo], playback_segments: list[SegmentInfo]
    ) -> list[PredictedFrameInfo]:
        """
        从action_points中移除playback片段范围内的所有动作点

        Returns:
            过滤后的动作点列表
        """
        if not playback_segments:
            return action_points

        filtered_action_points: list[PredictedFrameInfo] = []

        for action_point in action_points:
            is_in_playback: bool = False

            # 检查当前动作点是否在任何playback片段范围内
            for playback_segment in playback_segments:
                if (
                    playback_segment.start_seconds
                    <= action_point.seconds
                    <= playback_segment.end_seconds
                ):
                    is_in_playback = True
                    break

            # 如果不在playback片段内，则保留
            if not is_in_playback:
                filtered_action_points.append(action_point)

        return filtered_action_points

    def _pre_process(
        self, action_points: list[PredictedFrameInfo], is_ignore_playback: bool
    ) -> list[PredictedFrameInfo]:
        sorted_action_point: list[PredictedFrameInfo] = sorted(
            action_points, key=lambda x: x.seconds
        )

        filtered_action_points: list[PredictedFrameInfo] = sorted_action_point

        if is_ignore_playback:
            playback_segments: list[SegmentInfo] = self._get_playback_segments(sorted_action_point)
            filtered_action_points = self._remove_playback_segments(
                action_points, playback_segments
            )

        return filtered_action_points

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
        fire_segments: list[SegmentInfo] = []

        if not self.is_merge_fire_ball_and_play_ball:
            segment_detect_config = self._get_segment_detector_config(
                ActionType.PICK_BALL, SegmentDetectorConfig(2.0, 5)
            )

            fire_segments: list[SegmentInfo] = self._detect_continuous_classifier(
                final_action_points,
                ActionType.FIRE_BALL,
                interval_seconds=segment_detect_config.interval_seconds,
                window_count=segment_detect_config.window_count,
            )

        segment_detect_config = self._get_segment_detector_config(
            ActionType.PICK_BALL, SegmentDetectorConfig(2.0, 5)
        )

        play_segments: list[SegmentInfo] = self._detect_continuous_classifier(
            final_action_points,
            ActionType.PLAY_BALL,
            interval_seconds=segment_detect_config.interval_seconds,
            window_count=segment_detect_config.window_count,
        )

        segment_detect_config = self._get_segment_detector_config(
            ActionType.PICK_BALL, SegmentDetectorConfig(1.0, 3)
        )

        pick_segments: list[SegmentInfo] = self._detect_continuous_classifier(
            final_action_points,
            ActionType.PICK_BALL,
            interval_seconds=segment_detect_config.interval_seconds,
            window_count=segment_detect_config.window_count,
        )

        if self.is_merge_fire_ball_and_play_ball:
            all_segments: list[SegmentInfo] = play_segments
            match_segments_list: list[dict[ActionType, SegmentInfo]] = (
                self._filter_match_segments_without_fire_ball(all_segments)
            )
        else:
            all_segments: list[SegmentInfo] = self._merge_segments(
                fire_segments + play_segments + pick_segments
            )
            match_segments_list: list[dict[ActionType, SegmentInfo]] = self._filter_play_segments(
                all_segments
            )
        return match_segments_list, all_segments

    def _merge_segments(self, segments: list[SegmentInfo]) -> list[SegmentInfo]:
        """合并重叠的片段"""
        if not segments:
            return []

        sorted_segments = sorted(segments, key=lambda x: x.start_seconds)

        merged: list[SegmentInfo] = [sorted_segments[0]]

        for segment in sorted_segments[1:]:
            # 如果play_ball的前一个动作是pick_ball, 合并 fire_ball -> pick_ball -> play_ball 合并
            last = merged[-1]
            if (
                len(merged) > 1
                and (merged[-2].action_type == ActionType.FIRE_BALL)
                and segment.action_type == ActionType.PLAY_BALL
                and last.action_type == ActionType.PICK_BALL
            ):
                merged[-1] = SegmentInfo(
                    action_type=segment.action_type,
                    start_seconds=last.start_seconds,
                    end_seconds=segment.end_seconds,
                )
                continue

            # 如果相邻片段类型相同, 合并
            merged.append(segment)
            while len(merged) > 1 and merged[-1].action_type == merged[-2].action_type:
                remove = merged.pop()
                merged[-1] = SegmentInfo(
                    action_type=remove.action_type,
                    start_seconds=merged[-1].start_seconds,
                    end_seconds=remove.end_seconds,
                )
        return merged

    def _filter_play_segments(
        self, segments: list[SegmentInfo]
    ) -> list[dict[ActionType, SegmentInfo]]:
        """过滤出有效的游戏片段"""
        valid_segments: list[dict[ActionType, SegmentInfo]] = []
        valid_segment: dict[ActionType, SegmentInfo] = {}
        phase: int = 0

        for segment in segments:
            if phase == 0 and segment.action_type == ActionType.FIRE_BALL:
                valid_segment[ActionType.FIRE_BALL] = segment
                phase = 1
            elif phase == 1 and segment.action_type == ActionType.PLAY_BALL:
                valid_segment[ActionType.PLAY_BALL] = segment
                phase = 2
            elif phase == 2 and segment.action_type == ActionType.PICK_BALL:
                valid_segment[ActionType.PICK_BALL] = segment
                valid_segments.append(valid_segment)
                valid_segment = {}
                phase = 0
            elif phase == 2 and segment.action_type == ActionType.FIRE_BALL:
                valid_segments.append(valid_segment)
                valid_segment = {ActionType.FIRE_BALL: segment}
                phase = 1
            else:
                phase = 0
                valid_segment.clear()

        return valid_segments
