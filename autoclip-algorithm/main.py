from src import CONFIG_PATH
from src.main.config.config import Config, load_config
from src.main.constant.common_constant import JobType
from src.main.core.badminton_auto_clipper import BadmintonAutoClipper
from src.main.core.pingpong_auto_clipper import PingPongAutoClipper
from src.main.http.internal_http import InternalHttp
from src.main.logger import LOG
from src.main.service.large_model_service import LargeModelService
from src.main.service.video_edit_service import VideoEditService


def main():
    config: Config = load_config(CONFIG_PATH)
    auto_clip_config = config.auto_clip_config
    common_auto_clip_options = auto_clip_config.common_options
    large_model_service_config = config.large_model_service_config
    large_model_service = LargeModelService(large_model_service_config)
    if config.job_type == JobType.TRAIN_MODEL:
        large_model_service.train()
    elif config.job_type == JobType.SERVICE:
        http_client = InternalHttp(config.internal.http).client

        pingpong_auto_clipper = PingPongAutoClipper(
            auto_clip_config.ping_pong, common_auto_clip_options, large_model_service
        )
        badminton_auto_clipper = BadmintonAutoClipper(
            auto_clip_config.badminton, common_auto_clip_options, large_model_service
        )

        video_edit_service = VideoEditService(
            service_config=config.service_config,
            mysql_config=config.datasource_config.mysql,
            pingpong_auto_clipper=pingpong_auto_clipper,
            badminton_auto_clipper=badminton_auto_clipper,
            kafka_config=config.kafka_config,
            http_client=http_client,
        )
        try:
            video_edit_service.start()
        except Exception as e:
            video_edit_service.stop()
            LOG.error(f"启动服务失败: {e}")


if __name__ == "__main__":
    main()
