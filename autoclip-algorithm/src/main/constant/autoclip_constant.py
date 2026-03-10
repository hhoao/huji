from enum import Enum
from pathlib import Path

from pydantic import BaseModel


class ActionType(int, Enum):
    FIRE_BALL = 0
    PLAY_BALL = 1
    PICK_BALL = 2
    TRANSITION = 3
    PLAYBACK = 4

    @staticmethod
    def from_str(value: str) -> "ActionType":
        return ActionType[value.upper()]


class SportType(int, Enum):
    PING_PONG = 0
    BADMINTON = 1


class VideoInfo(BaseModel):
    fps: float
    duration: float
    total_frames: int
    is_vfr: bool
    r_frame_rate_str: str
    avg_frame_rate_str: str
    r_frame_rate_val: float
    avg_frame_rate_val: float
    video_path: str
    video_file: Path
    codec_name: str
    bit_rate: str

    def __str__(self) -> str:
        return (
            f"VideoInfo(fps={self.fps},"
            f" duration={self.duration},"
            f" total_frames={self.total_frames},"
            f" is_vfr={self.is_vfr},"
            f" r_frame_rate={self.r_frame_rate_str},"
            f" avg_frame_rate={self.avg_frame_rate_str})"
        )


class EndpointInfo(BaseModel):
    service: str
    region: str
    provider: str


ping_pong_classes_mapping: dict[str, ActionType] = {
    "fire_ball": ActionType.FIRE_BALL,
    "fireball": ActionType.FIRE_BALL,
    "play_ball": ActionType.PLAY_BALL,
    "playball": ActionType.PLAY_BALL,
    "pick_ball": ActionType.PICK_BALL,
    "pickball": ActionType.PICK_BALL,
    "transition": ActionType.TRANSITION,
    "playback": ActionType.PLAYBACK,
}

ping_pong_merge_fire_ball_and_play_ball_classes_mapping: dict[str, ActionType] = {
    "fire_ball": ActionType.PLAY_BALL,
    "fireball": ActionType.PLAY_BALL,
    "play_ball": ActionType.PLAY_BALL,
    "playball": ActionType.PLAY_BALL,
    "pick_ball": ActionType.PICK_BALL,
    "pickball": ActionType.PICK_BALL,
    "transition": ActionType.TRANSITION,
    "playback": ActionType.PLAYBACK,
}

badminton_classes_mapping: dict[str, ActionType] = {
    "play_ball": ActionType.PLAY_BALL,
    "playball": ActionType.PLAY_BALL,
    "pick_ball": ActionType.PICK_BALL,
    "pickball": ActionType.PICK_BALL,
    "transition": ActionType.TRANSITION,
    "playback": ActionType.PLAYBACK,
}


class SegmentInfo(BaseModel):
    action_type: ActionType
    start_seconds: float
    end_seconds: float


class SegmentDetectorConfig:
    def __init__(self, interval_seconds: float, window_count: int):
        self.interval_seconds = interval_seconds
        self.window_count = window_count


class PredictedFrameInfo(BaseModel):
    action_type: ActionType
    seconds: float


class VideoBaseInfo(BaseModel):
    duration: float
    size: int


class VideoClipOutputInfo(BaseModel):
    # 所有比赛合并视频路径
    all_match_merged_video_path: str
    # 精彩比赛视频路径列表
    great_match_video_path_list: list[str]
    # 所有比赛片段
    all_match_segments: list[dict[ActionType, SegmentInfo]]
    # 精彩比赛片段
    great_match_segments: list[dict[ActionType, SegmentInfo]]
    # 输入视频信息
    input_video_info: VideoInfo
    # 所有比赛合并视频信息
    all_match_merged_video_info: VideoBaseInfo
    # 精彩比赛视频信息列表
    great_match_video_info: list[VideoBaseInfo]

    def __str__(self) -> str:
        return f"""
        所有比赛合并视频路径: {self.all_match_merged_video_path}
        精彩比赛视频路径列表: {self.great_match_video_path_list}
        输入视频信息: {self.input_video_info}
        所有比赛合并视频信息: {self.all_match_merged_video_info}
        精彩比赛视频信息列表: {self.great_match_video_info}
        """


class MatchType(int, Enum):
    """比赛类型枚举"""

    DOUBLES_MATCH = 0  # 双打比赛
    SINGLES_MATCH = 1  # 单打比赛


class ModeEnum(int, Enum):
    BACKEND_CLIP = 0
    CUSTOM_CLIP = 1


class AutoClipConfig(BaseModel):
    pass


class CommonAutoClipConfig(BaseModel):
    # 比赛模式
    mode: ModeEnum | None = None
    # 比赛类型
    match_type: MatchType | None = None
    # 精彩球剪辑
    great_ball_editing: bool | None = None
    # 是否忽略回放
    remove_replay: bool | None = None
    # 开头预留时间
    reserve_time_before_single_round: float | None = None
    # 结尾预留时间
    reserve_time_after_single_round: float | None = None
    # 单局的最小持续时间
    minimum_duration_single_round: float | None = None
    # 精彩球的最小持续时间
    minimum_duration_great_ball: float | None = None

    def __str__(self) -> str:
        return f"""
        比赛模式: {self.mode}
        比赛类型: {self.match_type}
        精彩球剪辑: {self.great_ball_editing}
        是否忽略回放: {self.remove_replay}
        开头预留时间: {self.reserve_time_before_single_round}
        结尾预留时间: {self.reserve_time_after_single_round}
        单局的最小持续时间: {self.minimum_duration_single_round}
        精彩球的最小持续时间: {self.minimum_duration_great_ball}

        """


class PingPongAutoClipConfig(CommonAutoClipConfig):
    # 发球的最大持续时间
    fireball_max_seconds: float | None = None
    merge_fire_ball_and_play_ball: bool | None = True


class BadmintonAutoClipConfig(CommonAutoClipConfig):
    pass
