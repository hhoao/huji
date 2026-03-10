import math

from src.main.utils import video_utils
from src.main.utils.common_util import timer
from src.test.base.test_base import TestCaseBase


class TestVideoUtils(TestCaseBase):
    def _setup_internal(self):
        pass

    def test_get_video_info(self):
        video_info = video_utils.get_video_info(
            # path_utils.get_resource("/video/examples/test.mp4"),
            # "/home/hhoa/Videos/pingpong/VID_20250421124915.mp4"
            "/home/hhoa/autoclip/autoclip-algorithm/src/test/utils/test.mp4"
        )
        print(video_info)
        print(math.ceil(video_info.avg_frame_rate_val))

    def test_resize(self):
        video_utils.resize_video_ratio(
            "/home/hhoa/Downloads/VID20\
            250727162021_compressed_medi\
            um_ultrafast_1753756256722_compressed_ultraLow_ultrafast_1753972803380_1753982138480.mp4",
            width=520,
            output_file="test.mp4",
        )

    def test_convert_to_cfr_if_variable_frame_rate(self):
        with timer("转换为 CFR"):
            video_utils.convert_to_cfr_if_variable_frame_rate(
                # "/home/hhoa/Videos/pingpong/output1.mp4",
                "/home/hhoa/Videos/pingpong/singles/2100分是什么水平-240815-p01-80(BV1MCeHeXEMN).mp4",
                output_file="test.mp4",
            )
