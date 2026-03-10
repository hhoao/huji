from httpx import Client

from src.main.constant.progress_constant import (
    ActionProgressProportion,
    UpdateProgressReqVO,
    VideoProcessState,
)
from src.main.constant.server_api import ServerApi
from src.main.logger import LOG


class ProgressHandler:
    def __init__(self, internal_client: Client, record_id: int, user_id: int):
        self._current_progress = 0
        self._internal_client = internal_client
        self._record_id = record_id
        self._user_id = user_id

    def add_multiple_progress(
        self,
        total: float,
        additive: float,
        progress_proportion: ActionProgressProportion,
        status: VideoProcessState,
    ) -> None:
        predict_frame_progress_proportion: float = ActionProgressProportion.get_proportion(
            progress_proportion
        )
        progress = additive / total * predict_frame_progress_proportion
        self._add_progress(progress, status)
        LOG.info(f"当前进度为: {progress}, 状态: {status}")

    def _add_progress(self, progress: float, status: VideoProcessState) -> None:
        self._current_progress += progress
        update_progress_req_vo = UpdateProgressReqVO(
            record_id=self._record_id,
            progress=self._current_progress,
            status=status,
            user_id=self._user_id,
        )
        self._internal_client.post(
            ServerApi.UPDATE_PROGRESS,
            json=update_progress_req_vo.model_dump(),
        )
        LOG.info(f"当前进度为: {progress}, 状态: {status}")

    def add_progress_proportion(
        self, progress_proportion: ActionProgressProportion, status: VideoProcessState
    ) -> None:
        self._add_progress(progress_proportion.get_proportion(progress_proportion), status)
