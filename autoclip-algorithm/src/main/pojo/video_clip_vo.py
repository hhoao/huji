import enum
from typing import Any

from pydantic import BaseModel, Field

from src.main.constant.autoclip_constant import (
    ActionType,
    SegmentInfo,
    SportType,
)


class HandleVideoMessageTopic:
    START_TOPIC = "HANDLE_VIDEO_MESSAGE_START_TOPIC"


class ClipVideoByUrlVO(BaseModel):
    config_id: int
    path: str
    file_type: str


class ClipVideoByFileVO(BaseModel):
    config_id: int
    file_type: str


class FileCreateInfo(BaseModel):
    config_id: int | None
    path: str | None
    name: str
    type: str
    url: str
    size: int


class MathchPhaseType(int, enum.Enum):
    ALL_MATCH_MERGED = 0
    GREAT_MATCH = 1


class OutputVideoInfo(BaseModel):
    match_segments: list[dict[ActionType, SegmentInfo]]
    match_video_path: str
    total_size: int
    total_duration: float

    def __str__(self) -> str:
        return f"""
        match_video_path: {self.match_video_path}
        total_size: {self.total_size}
        total_duration: {self.total_duration}
        """


class VideoClipResult(BaseModel):
    all_match_merged_output_video_info: OutputVideoInfo
    great_match_output_video_info: OutputVideoInfo | None

    def __str__(self) -> str:
        return f"""
        all_match_merged_output_video_info: {self.all_match_merged_output_video_info}
        great_match_output_video_info: {self.great_match_output_video_info}
        """


class CommonVideoClipConfig(BaseModel):
    great_ball_editing: bool | None = Field(None, description="精彩球剪辑(长球)")
    remove_replay: bool | None = Field(None, description="移除回放")
    get_match_segments: bool | None = Field(None, description="单独获取所有比赛段")
    reserve_time_before_single_round: float | None = Field(None, description="每轮比赛前预留时间")
    reserve_time_after_single_round: float | None = Field(None, description="每轮比赛后预留时间")

    minimum_duration_single_round: float | None = Field(None, description="单局的最小持续时间")
    minimum_duration_great_ball: float | None = Field(None, description="精彩球的最小持续时间")


class HandleVideoMessageResultTypeEnum(int, enum.Enum):
    FAILURE = 0
    SUCCESS = 1


class HandleVideoMessage(BaseModel):
    file_info: FileCreateInfo
    video_clip_config: dict[str, Any] | None = None
    sport_type: SportType
    user_id: int
    record_id: int | None = None


class VideoClipResultMessage(BaseModel):
    video_clip_result: VideoClipResult | None
    config_id: int | None
    name: str
    user_id: int
    result_type: HandleVideoMessageResultTypeEnum | None = None
    result_message: str | None = None
    record_id: int | None = None

    def __str__(self) -> str:
        return f"""
        video_clip_result: {self.video_clip_result}
        config_id: {self.config_id}
        name: {self.name}
        user_id: {self.user_id}
        result_type: {self.result_type}
        result_message: {self.result_message}
        record_id: {self.record_id}
        """


class VideoSegmentInfo(BaseModel):
    video_path: str
    start_time: float
    end_time: float
