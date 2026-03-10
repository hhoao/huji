from enum import IntEnum

from pydantic import BaseModel


class VideoProcessState(IntEnum):
    # 等待中
    PREPARING = 0
    # 处理中
    PROCESSING = 1
    # 已完成
    COMPLETED = 2
    # 处理失败
    FAILED = 3


class UpdateProgressReqVO(BaseModel):
    record_id: int
    progress: float
    status: VideoProcessState
    user_id: int


class ActionProgressProportion(IntEnum):
    START = 20
    RESIZE_VIDEO = 40
    PREDICT_VIDEO_ACTION_POINTS = 260
    MERGE_AND_CLIP_VIDEO = 40

    @classmethod
    def get_proportion(cls, action: "ActionProgressProportion") -> float:
        return action.value / sum([i.value for i in list(cls)])
