import json

from src.main.constant.autoclip_constant import BadmintonAutoClipConfig, MatchType
from src.main.core.badminton_auto_clipper import BadmintonAutoClipper
from src.main.core.pingpong_auto_clipper import PingPongAutoClipper
from src.main.service.large_model_service import LargeModelService
from src.test.base.test_base import TestCaseBase


class TestAutoClipper(TestCaseBase):
    def _setup_internal(self):
        large_model_service = LargeModelService(self.config.large_model_service_config)
        self.ping_pong_auto_clipper: PingPongAutoClipper = PingPongAutoClipper(
            self.config.auto_clip_config.ping_pong,
            self.config.auto_clip_config.common_options,
            large_model_service,
        )
        self.badminton_auto_clipper: BadmintonAutoClipper = BadmintonAutoClipper(
            self.config.auto_clip_config.badminton,
            self.config.auto_clip_config.common_options,
            large_model_service,
        )

    def test_ping_pong_clip(self):
        # self.ping_pong_auto_clipper.autoclip_video(get_resource("video/examples/test.mp4"))
        self.ping_pong_auto_clipper.autoclip_video(
            # get_resource("video/examples/test.mp4")
        # "/home/hhoa/Videos/pingpong/VID_20250421124915.mp4"
        # "/home/hhoa/Videos/pingpong/singles/2100分是什么水平-240815-p01-80(BV1MCeHeXEMN).mp4"
        # "/home/hhoa/autoclip/autoclip-algorithm/src/test/utils/test.mp4"
        # "/home/hhoa/Downloads/VID20250831191619.mp4"
        # "/home/hhoa/Downloads/VID20250830135655.mp4"
        # "/home/hhoa/Downloads/VID20250831191619-30fps.mp4"
        # "/home/hhoa/Videos/1762171250419.mp4"
        #     1:21
        # "/home/hhoa/Downloads/test/VID20250830135655.mp4"
        "/home/hhoa/Videos/未命名1.mp4"
        # "/home/hhoa/Downloads/VID20250830152324.mp4"
            # "/home/hhoa/Videos/error/VID20250712214213-1752335470.145742.mp4"
            # "/home/hhoa/Videos/error/mmexport1747238643511_1753805249007.mp4"
            # "/home/hhoa/Videos/未命名.mp4"
            # "/home/hhoa/Videos/error/video_20250715_122123_1752564061738.mp4"
            # "/home/hhoa/Videos/error/video_20250724_105353_1753364001370.mp4"
        )

    def test_badminton_clip(self):
        # self.badminton_auto_clipper.autoclip_video(get_resource("video/examples/blue.mp4"))
        self.badminton_auto_clipper.autoclip_video(
            "/home/hhoa/Videos/VID_20250713_115348_1752465148357.mp4"
        )

    def test_badminton_double_clip(self):
        config = BadmintonAutoClipConfig(match_type=MatchType.DOUBLES_MATCH)
        self.badminton_auto_clipper.autoclip_video(
            # input_video_path=get_resource("video/examples/badminton_doubles_1.mp4"),
            # input_video_path="/home/hhoa/Downloads/VID_20250724_124811_1753405617692.mp4",
            input_video_path="/home/hhoa/Downloads/VID_20250722_200114_1753250843489.mp4",
            # input_video_path="/home/hhoa/Videos/badminton/双打/20250619伯明顿羽毛球.mp4",
            auto_clip_config=json.loads(config.model_dump_json()),
        )

    # def test_predict(self):
    #     model = YOLO(model_path)
    #     results =model(frames, stream=True, stream_buffer=True)
    #     # res = model.predict(frames, stream=True)  # type: ignore
    #     for result in results:
    #         top1: str = result.names[r.probs.top1]  # type: ignore
    #         ret.append(top1)
