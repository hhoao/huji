from src.main.core.pingpong_auto_clipper import PingPongAutoClipper
from src.main.service.large_model_service import LargeModelService
from src.main.utils.common_util import timer
from src.test.base.test_base import TestCaseBase


class TestPredictService(TestCaseBase):
    def _setup_internal(self):
        large_model_service = LargeModelService(self.config.large_model_service_config)
        self.predict_service = PingPongAutoClipper(
            self.config.auto_clip_config.ping_pong,
            self.config.auto_clip_config.common_options,
            large_model_service,
        )

    def test_auto_clip_video(self):
        with timer("自动剪辑视频"):
            self.predict_service.autoclip_video("")
