import json
import time
from pathlib import Path
from threading import Thread

from confluent_kafka import Producer  # type: ignore

from src.main.core.badminton_auto_clipper import BadmintonAutoClipper
from src.main.core.pingpong_auto_clipper import PingPongAutoClipper
from src.main.http.internal_http import InternalHttp
from src.main.pojo.video_clip_vo import HandleVideoMessage
from src.main.service.large_model_service import LargeModelService
from src.main.service.message_service import MessageService
from src.main.utils import path_utils
from src.test.base.test_base import TestCaseBase


class TestFileSystemService(TestCaseBase):
    def _setup_internal(self):
        self.http_client = InternalHttp(self.config.internal.http).client
        self.large_model_service = LargeModelService(self.config.large_model_service_config)

        self.service = MessageService(
            self.config.service_config,
            self.config.kafka_config,
            PingPongAutoClipper(
                self.config.auto_clip_config.ping_pong,
                self.config.auto_clip_config.common_options,
                self.large_model_service,
            ),
            BadmintonAutoClipper(
                self.config.auto_clip_config.badminton,
                self.config.auto_clip_config.common_options,
                self.large_model_service,
            ),
            self.http_client,
        )
        self.service.remote_video_output_dir = "output/remote/output"

    def get_pingpong_local_message(self):
        json_str = Path(path_utils.get_resource("/test/pingpong/message_local.json")).read_text(
            encoding="utf-8"
        )
        t_obj = json.loads(json_str)
        return HandleVideoMessage(**t_obj)

    def get_pingpong_normal_message(self):
        json_str = Path(
            path_utils.get_resource("/test/pingpong/message_remote_with_record_id.json")
        ).read_text(encoding="utf-8")
        t_obj = json.loads(json_str)
        return HandleVideoMessage(**t_obj)

    def get_pingpong_only_url_video_messsge(self):
        json_str = Path(path_utils.get_resource("/test/pingpong/no_path.json")).read_text(
            encoding="utf-8"
        )
        t_obj = json.loads(json_str)
        return HandleVideoMessage(**t_obj)

    def get_badminton_only_url_video_messsge(self):
        json_str = Path(path_utils.get_resource("/test/badminton/no_path.json")).read_text(
            encoding="utf-8"
        )
        t_obj = json.loads(json_str)
        return HandleVideoMessage(**t_obj)

    def get_badminton_doubles_messsge(self):
        json_str = Path(
            path_utils.get_resource("/test/badminton/doubles_clip_remote_message.json")
        ).read_text(encoding="utf-8")
        t_obj = json.loads(json_str)
        return HandleVideoMessage(**t_obj)

    def get_badminton_normal_message(self):
        json_str = Path(
            path_utils.get_resource("/test/badminton/message_remote_with_record_id.json")
        ).read_text(encoding="utf-8")
        t_obj = json.loads(json_str)
        return HandleVideoMessage(**t_obj)

    def test_send_process_badminton_singles_message(self):
        messages = [
            self.get_badminton_only_url_video_messsge(),
            self.get_badminton_normal_message(),
        ]
        self.send_and_receive_message(messages)

    def test_send_process_badminton_doubles_message(self):
        messages = [
            self.get_badminton_doubles_messsge(),
        ]
        self.send_and_receive_message(messages)

    def test_send_process_pingpong_message(self):
        messages = [
            # self.get_pingpong_only_url_video_messsge(),
            self.get_pingpong_normal_message(),
        ]
        self.send_and_receive_message(messages)

    def send_and_receive_message(self, messages: list[HandleVideoMessage]):
        """测试发送消息到Kafka并验证消费者是否能正确接收和处理"""

        Thread(target=self.service.start).start()
        time.sleep(5)

        producer_config = {
            "bootstrap.servers": self.config.kafka_config.bootstrap_servers,
        }
        producer = Producer(producer_config)

        for message in messages:
            message_json = message.model_dump_json()
            producer.produce(
                topic=self.config.service_config.handle_video_message_topic, value=message_json
            )
        producer.flush()
        time.sleep(60)
        self.service.stop()
        producer.flush()
