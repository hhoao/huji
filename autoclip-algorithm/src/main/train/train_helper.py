import os
from pathlib import Path

from src.main.constant.autoclip_constant import (
    ActionType,
    PredictedFrameInfo,
    SegmentInfo,
)
from src.main.core.action_segment_detector import ActionSegmentDetector
from src.main.core.badminton_auto_clipper import BadmintonAutoClipper
from src.main.core.pingpong_auto_clipper import PingPongAutoClipper
from src.main.utils import path_utils, video_utils


def create_classify_frames(
    auto_clipper: BadmintonAutoClipper | PingPongAutoClipper,
    action_segment_detector: ActionSegmentDetector,
    video_path: str,
    model_name: str,
    class_mappings: dict[str, ActionType],
    base_dir: str,
):
    action_points: list[PredictedFrameInfo] = auto_clipper.predict_video_action_points_internal_v2(
        video_path, model_name, class_mappings, workers=4
    )
    segments: tuple[list[dict[ActionType, SegmentInfo]], list[SegmentInfo]] = (
        action_segment_detector.convert_action_point_to_game_segments(action_points)
    )
    all_segments: list[dict[ActionType, SegmentInfo]] = segments[0]
    video_name = Path(video_path).stem

    for segment in all_segments:
        for action_type, segment_info in segment.items():
            temp_dir = path_utils.path_join(
                base_dir,
                f"{video_name}",
                f"{action_type}",
                "frames",
                f"{segment_info.start_seconds}-{segment_info.end_seconds}",
            )
            video_output_file = path_utils.path_join(
                base_dir,
                f"{video_name}",
                f"{action_type}",
                "video",
                f"{segment_info.start_seconds}-{segment_info.end_seconds}.mp4",
            )
            os.makedirs(temp_dir, exist_ok=True)
            os.makedirs(os.path.dirname(video_output_file), exist_ok=True)
            video_utils.clip_video_by_times(
                input_file=video_path,
                start_time=segment_info.start_seconds,
                duration=segment_info.end_seconds - segment_info.start_seconds,
                output_file=video_output_file,
            )
            video_utils.interval_extract_frames(
                video_path=video_output_file,
                frame_interval=5,
                temp_dir=temp_dir,
            )

    return action_points
