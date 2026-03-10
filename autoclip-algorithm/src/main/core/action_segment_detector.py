from abc import ABC, abstractmethod
from collections import deque

from src.main.constant.autoclip_constant import ActionType, PredictedFrameInfo, SegmentInfo


class ActionSegmentDetector(ABC):
    @abstractmethod
    def convert_action_point_to_game_segments(
        self, action_points: list[PredictedFrameInfo]
    ) -> tuple[list[dict[ActionType, SegmentInfo]], list[SegmentInfo]]:
        """
        将动作点转换为比赛片段

        :param action_points: 动作点
        :return: 比赛片段
        """
        pass

    def _detect_continuous_classifier(
        self,
        actions: list[PredictedFrameInfo],
        action_type: ActionType,
        interval_seconds: float = 2.0,
        window_count: int = 4,
    ) -> list[SegmentInfo]:
        """检测连续动作片段 - 使用队列优化滑动窗口"""
        filtered_actions: list[PredictedFrameInfo] = [
            a for a in actions if a.action_type == action_type
        ]
        if not filtered_actions:
            return []

        segments: list[SegmentInfo] = []
        n = len(filtered_actions)
        window: deque[PredictedFrameInfo] = deque()  # 维护滑动窗口
        start = 0  # 当前窗口的起始索引
        end = 0  # 当前窗口的结束索引

        while end < n:
            # 将当前动作加入窗口loat
            window.append(filtered_actions[end])

            # 移除窗口外的动作(保持窗口大小为interval_ms)
            while window and (window[-1].seconds - window[0].seconds > interval_seconds):
                window.popleft()
                start += 1

            # 检查窗口内动作数量是否达到min_count
            if len(window) >= window_count:
                # 尝试扩展窗口以找到最长有效片段
                max_end = end
                while max_end + 1 < n:
                    next_action = filtered_actions[max_end + 1]
                    window.append(next_action)

                    # 移除窗口外的动作
                    while window and (window[-1].seconds - window[0].seconds > interval_seconds):
                        window.popleft()

                    # 如果扩展后窗口仍有效
                    if len(window) >= window_count:
                        max_end += 1
                    else:
                        break

                # 创建片段
                segment = SegmentInfo(
                    action_type=action_type,
                    start_seconds=filtered_actions[start].seconds,
                    end_seconds=filtered_actions[max_end].seconds,
                )
                segments.append(segment)

                # 跳过已处理的动作
                end = max_end + 1
                start = end
                window.clear()
            else:
                end += 1

        return segments

    def _filter_match_segments_without_fire_ball(
        self, segments: list[SegmentInfo]
    ) -> list[dict[ActionType, SegmentInfo]]:
        """过滤出有效的比赛片段"""
        valid_segments: list[dict[ActionType, SegmentInfo]] = []
        valid_segment: dict[ActionType, SegmentInfo] = {}

        for segment in segments:
            if segment.action_type == ActionType.PLAY_BALL:
                valid_segment[ActionType.PLAY_BALL] = segment
                valid_segments.append(valid_segment)
                valid_segment = {}

        return valid_segments
