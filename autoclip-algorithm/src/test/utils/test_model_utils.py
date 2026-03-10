from src.main.utils import model_utils
from src.test.base.test_base import TestCaseBase


class TestVideoUtils(TestCaseBase):
    def _setup_internal(self):
        pass

    def test_export_ping_pong_model_tflite(self):
        model_utils.export_model(
            "/home/hhoa/autoclip/autoclip-algorithm/src/resources/models/ping_pong/profession/best.pt",
            model_utils.ModelFormatType.TFLITE
        )

    def test_export_badminton_model_tflite(self):
        model_utils.export_model(
            "/home/hhoa/autoclip/autoclip-algorithm/src/resources/models/badminton/singles/best.pt",
            model_utils.ModelFormatType.TFLITE
        )


