import datetime
import json
import os
import tempfile
import threading
import time
import traceback
import zipfile
from pathlib import Path
from queue import Empty as QueueEmpty
from queue import Queue
from typing import Any

import requests
from confluent_kafka import Consumer, KafkaError, Message, Producer
from httpx import Client
from pydantic import BaseModel

from src.main.config.config import KafkaConfig, ServiceConfig
from src.main.constant.autoclip_constant import (
    ActionType,
    SegmentInfo,
    SportType,
    VideoBaseInfo,
    VideoClipOutputInfo,
)
from src.main.constant.error_codes import ServiceError
from src.main.constant.progress_constant import ActionProgressProportion, VideoProcessState
from src.main.constant.server_api import ServerApi
from src.main.core.badminton_auto_clipper import BadmintonAutoClipper
from src.main.core.pingpong_auto_clipper import (
    CleanableFileCollection,
    PingPongAutoClipper,
)
from src.main.filesystem import FileSystem
from src.main.logger import LOG
from src.main.pojo.video_clip_vo import (
    FileCreateInfo,
    HandleVideoMessage,
    HandleVideoMessageResultTypeEnum,
    OutputVideoInfo,
    VideoClipResult,
    VideoClipResultMessage,
)
from src.main.service.filesystem_service import FileSystemService
from src.main.service.progress_handler import ProgressHandler
from src.main.service.video_clip_helper import generate_file_name
from src.main.utils import path_utils
from src.main.utils.common_util import timer


def _parse_request_message(
    message: Message,
) -> HandleVideoMessage:
    data = message.value()
    if data is None:
        raise Exception("message is None")

    if isinstance(data, str):
        json_data = json.loads(data)
    elif isinstance(data, dict):
        json_data = data
    else:
        json_data = json.loads(data.decode("utf-8"))

    res: HandleVideoMessage = HandleVideoMessage(**json_data)  # type: ignore
    return res


"""
前端请求后端
后端将消息放入kafka   （handleVideoToipc）(文件信息，用户信息)
后端开始一个定时任务，判断指定时间后消息有没有处理完成，并存储当前任务的信息
python获取kafka消息，放入一个异步队列中    （handleVideoToipc）
python预测视频线程获取队列消息，开始预测，并提交kafka消息
剪辑完成，python将剪辑后的视频信息放入kafka     （videoSuccessToipc）
剪辑失败，python将剪辑失败的信息发送给后端
如果中途挂了，定时任务会重新将消息放入队列中，并系统通知
成功后，后端获取kafka预测视频数据消息，判断是否完成过，如果未完成，那么，取消定时任务，存储视频信息（videoSuccessToipc）
最后后端通知用户消息已经完成   (站内信发送)（notifyVideoToipc）

以上情况可以精确Exactly Once

那如果一个Partition 有一个任务处理了很久导致消息被堆积怎么办？
或许每个Consumer 可以另起一个线程，这个线程用来判断队列是否堆积，如果堆积，则重新将消息放入Kafka中。
就算中途可能出现一些问题，导致视频重新预测，可是毕竟这种情况还是少数，而且后端也有信息记录，视频虽然多次处理，但只会存储一次信息
"""


class FilePresignedUrlResp(BaseModel):
    """管理后台 - 文件预签名地址 Response VO"""

    config_id: int
    upload_url: str
    url: str
    path: str


class VideoUploader:
    def __init__(self, file_system: FileSystem | None, client: Client):
        self.file_system = file_system
        self.client = client

    def _get_presigned_url(
        self,
        name: str,
        directory: str | None = None,
        is_generate_prefix_and_suffix: bool = False,
    ) -> FilePresignedUrlResp:
        """Get presigned URL from service endpoint"""
        params: dict[str, Any] = {"name": name}
        if directory:
            params["directory"] = directory
        params["is_generate_prefix_and_suffix"] = is_generate_prefix_and_suffix

        response = self.client.get(ServerApi.INFR_FILE_PRESIGNED_URL, params=params)
        return FilePresignedUrlResp(**response.json())

    def upload_video(self, local_path: str, remote_path: str):
        if self.file_system is not None:
            self.file_system.upload_file(local_path, remote_path)
        else:
            remote_video_output_dir = Path(remote_path).parent.as_posix()
            file_name = Path(remote_path).name
            presigned_url_resp = self._get_presigned_url(
                file_name, remote_video_output_dir, is_generate_prefix_and_suffix=False
            )
            with timer("文件上传:", remote_path), open(local_path, "rb") as f:
                response = requests.put(presigned_url_resp.upload_url, data=f, timeout=36000)
                response.raise_for_status()


class MessageService:
    def __init__(
        self,
        service_config: ServiceConfig,
        kafka_config: KafkaConfig,
        pingpong_auto_clipper: PingPongAutoClipper,
        badminton_auto_clipper: BadmintonAutoClipper,
        http_client: Client,
        test_filesystem: FileSystem | None = None,
    ) -> None:
        self.process_video_result_url: str = service_config.video_result_processor_url
        self.kafka_config: KafkaConfig = kafka_config
        self.max_content_length: int = service_config.max_content_length
        self.video_save_tempfolder: str = tempfile.mkdtemp()
        self.allowed_extensions: set[str] = {"video/mp4", "mp4", "avi", "mov", "mkv"}
        self.host: str = service_config.host
        self.port: int = service_config.port
        self.debug: bool = service_config.debug
        self.remote_video_output_dir: str = service_config.remote_video_output_dir
        self.file_system_client_service: FileSystemService = FileSystemService(http_client)
        self.test_filesystem = test_filesystem
        self.handle_video_message_topic: str = service_config.handle_video_message_topic
        self.is_local = False
        self.async_process_message: bool = service_config.async_process_message

        # 配置 Kafka 消费者
        consumer_config = {
            "bootstrap.servers": self.kafka_config.bootstrap_servers,
            "group.id": self.kafka_config.consumer_group,
            "auto.offset.reset": self.kafka_config.auto_offset_reset,
            "enable.auto.commit": False,
            "max.poll.interval.ms": 1000 * 60 * 60 * 24,
            "heartbeat.interval.ms": 1000 * 5,
            "session.timeout.ms": 1000 * 15,
            "allow.auto.create.topics": True,
        }

        self.consumer: Consumer = Consumer(consumer_config)
        self.consumer.subscribe([self.handle_video_message_topic])
        self.pingpong_auto_clipper: PingPongAutoClipper = pingpong_auto_clipper
        self.badminton_auto_clipper: BadmintonAutoClipper = badminton_auto_clipper
        self.running: bool = False
        self.http_client: Client = http_client

        # 本地消息队列，每个消费者实例独立
        self.message_queue: Queue[Message] = Queue()
        self.processing_thread: threading.Thread | None = None
        self.processing_lock = threading.Lock()

    def start(self) -> None:
        """
        启动消息处理服务。
        每个消费者实例都会：
        1. 从Kafka获取分配给自己的消息
        2. 将消息放入自己的本地队列
        3. 在自己的处理线程中处理消息
        """
        self.running = True
        LOG.info("开始消费Kafka消息...")

        # 启动处理线程
        self.processing_thread = threading.Thread(target=self._process_messages)
        self.processing_thread.start()

        while self.running:
            try:
                msg: Message | None = self.consumer.poll(1.0)
                if msg is None:
                    continue

                error = msg.error()
                if error and error.code() == KafkaError._PARTITION_EOF:
                    continue
                if error:
                    LOG.error(f"Consumer error: {error}")
                    continue

                LOG.info(
                    f"开始处理消息 - Topic: {msg.topic()}, "
                    f"partition: {msg.partition()}, "
                    f"offset: {msg.offset()}, "
                    f"consumer_group: {self.kafka_config.consumer_group}"
                )

                if self.async_process_message:
                    self._async_process_message(msg)
                else:
                    self.process_video_clip(msg)

            except InterruptedError as e:
                LOG.error(f"服务发生中断: {e}")
                LOG.error(traceback.format_exc())
                self.running = False
            except Exception as e:
                LOG.error(f"处理消息时发生错误: {e}")
                LOG.error(traceback.format_exc())
                time.sleep(5)

        self._end()

    def _end(self):
        if self.consumer:
            self.consumer.close()
        LOG.info("Kafka消费者已关闭")

    def _async_process_message(self, msg: Message) -> None:
        self.message_queue.put(msg)
        self.consumer.commit()

    def _process_messages(self) -> None:
        """
        处理本地队列中的消息。
        每个消费者实例都有自己的处理线程，
        处理分配给自己的分区的消息。
        """
        while self.running:
            try:
                msg = self.message_queue.get(timeout=1.0)

                with self.processing_lock:
                    try:
                        with timer("开始处理消息", str(msg)):
                            self.process_video_clip(msg)

                        LOG.info(
                            f"消息处理完成并提交 - Topic: {msg.topic()}, "
                            f"partition: {msg.partition()}, "
                            f"offset: {msg.offset()}, "
                            f"consumer_group: {self.kafka_config.consumer_group}"
                        )
                    except Exception as e:
                        LOG.error(
                            f"处理消息时发生错误: {e}, "
                            f"message: {msg.value() if msg else None}, "
                            f"topic: {msg.topic()}, "
                            f"partition: {msg.partition()}, "
                            f"offset: {msg.offset()}"
                        )
                        LOG.error(traceback.format_exc())
                    finally:
                        self.message_queue.task_done()

            except QueueEmpty:
                continue
            except Exception as e:
                LOG.error(f"消息处理线程发生错误: {e}")
                LOG.error(traceback.format_exc())
                time.sleep(5)

    def process_video_clip(self, msg: Message) -> None:
        handle_video_message = _parse_request_message(msg)
        file_info = handle_video_message.file_info

        cleanable_file_collection = CleanableFileCollection()
        try:
            # 创建进度处理器，并添加开始进度
            if handle_video_message.record_id is not None:
                progress_handler = ProgressHandler(
                    self.http_client, handle_video_message.record_id, handle_video_message.user_id
                )
                progress_handler.add_progress_proportion(
                    ActionProgressProportion.START,
                    VideoProcessState.PROCESSING,
                )
            else:
                progress_handler = None

            # 生成输入文件
            input_filename = generate_file_name(file_info.name, file_info.type)
            input_path = os.path.join(self.video_save_tempfolder, input_filename)

            video_clip_config = handle_video_message.video_clip_config

            if video_clip_config is None:
                raise ValueError("video_clip_config is None")

            # 开始处理视频
            if self.is_local:
                video_clip_result = self.process_video_local(
                    file_info,
                    input_path,
                    handle_video_message.sport_type,
                    video_clip_config,
                    progress_handler,
                    cleanable_file_collection,
                )
            else:
                video_clip_result = self.process_video_remote(
                    file_info,
                    input_path,
                    handle_video_message.sport_type,
                    video_clip_config,
                    progress_handler,
                    cleanable_file_collection,
                )

            success_message = VideoClipResultMessage(
                config_id=file_info.config_id,
                name=file_info.name,
                video_clip_result=video_clip_result,
                user_id=handle_video_message.user_id,
                result_type=HandleVideoMessageResultTypeEnum.SUCCESS,
                result_message="success",
                record_id=handle_video_message.record_id,
            )

            self._send_message(success_message)
        except Exception as e:
            if isinstance(e, ServiceError):
                result_message = str(e.error_code.message)
            else:
                result_message = "视频处理内部错误"
            failure_message = VideoClipResultMessage(
                config_id=file_info.config_id,
                name=file_info.name,
                video_clip_result=None,
                user_id=handle_video_message.user_id,
                result_type=HandleVideoMessageResultTypeEnum.FAILURE,
                result_message=result_message,
                record_id=handle_video_message.record_id,
            )
            self._send_message(failure_message)
            raise e
        finally:
            self.consumer.commit()
            # cleanable_file_collection.clean()

    def _upload_and_create_result(
        self,
        video_uploader: VideoUploader,
        video_clip_output_info: VideoClipOutputInfo,
        remote_video_output_dir: str,
    ) -> VideoClipResult:
        remote_all_match_output_dir = path_utils.path_join(remote_video_output_dir, "all_match")
        remote_great_match_output_dir = path_utils.path_join(remote_video_output_dir, "great_match")
        all_match_output_video_info = self._upload_and_create_all_match_output_video_info(
            video_uploader=video_uploader,
            all_match_segments=video_clip_output_info.all_match_segments,
            all_match_merged_video_path=video_clip_output_info.all_match_merged_video_path,
            all_match_merged_video_info=video_clip_output_info.all_match_merged_video_info,
            remote_video_output_dir=remote_all_match_output_dir,
        )
        great_match_output_video_info = self._create_great_output_video_info(
            video_uploader=video_uploader,
            great_match_video_path_list=video_clip_output_info.great_match_video_path_list,
            great_match_segments=video_clip_output_info.great_match_segments,
            great_match_video_info=video_clip_output_info.great_match_video_info,
            remote_video_output_dir=remote_great_match_output_dir,
        )

        result_file_info = VideoClipResult(
            all_match_merged_output_video_info=all_match_output_video_info,
            great_match_output_video_info=great_match_output_video_info,
        )
        return result_file_info

    def process_video_remote(
        self,
        file_info: FileCreateInfo,
        input_path: str,
        sports_type: SportType,
        auto_clip_config: dict[str, Any] | None,
        progress_handler: ProgressHandler | None,
        cleanable_file_collection: CleanableFileCollection,
    ) -> VideoClipResult:
        with timer("文件下载"):
            filesystem = self.download_remote_file(file_info, input_path)

        # 真正开始剪辑视频
        if sports_type == SportType.PING_PONG:
            video_clip_output_info: VideoClipOutputInfo = self.pingpong_auto_clipper.autoclip_video(
                input_path, auto_clip_config, progress_handler, cleanable_file_collection
            )
        elif sports_type == SportType.BADMINTON:
            video_clip_output_info: VideoClipOutputInfo = (
                self.badminton_auto_clipper.autoclip_video(
                    input_path, auto_clip_config, progress_handler, cleanable_file_collection
                )
            )

        remote_video_output_dir = path_utils.path_join(
            self.remote_video_output_dir,
            datetime.datetime.now().strftime("%Y%m%d"),
        )

        video_uploader = VideoUploader(file_system=filesystem, client=self.http_client)
        upload_and_create_result: VideoClipResult = self._upload_and_create_result(
            video_uploader,
            video_clip_output_info,
            remote_video_output_dir,
        )
        return upload_and_create_result

    def download_remote_file(self, file_info: FileCreateInfo, input_path: str):
        if not file_info.url.startswith(("http:", "https:")):
            raise ValueError(f"url: {file_info.url} 不是http url")
        if (
            file_info.path is not None
            and len(file_info.path) != 0
            and file_info.config_id is not None
        ):
            filesystem = self.file_system_client_service.get_filesystem(file_info.config_id)
            filesystem.download_file(file_info.path, input_path)
        else:
            filesystem = None
            response = requests.get(file_info.url, stream=True, timeout=36000)
            response.raise_for_status()
            with open(input_path, "wb") as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
        return filesystem

    def _upload_and_create_all_match_output_video_info(
        self,
        video_uploader: VideoUploader,
        all_match_segments: list[dict[ActionType, SegmentInfo]],
        all_match_merged_video_path: str,
        all_match_merged_video_info: VideoBaseInfo,
        remote_video_output_dir: str,
    ) -> OutputVideoInfo:
        remote_video_output_path = path_utils.path_join(
            remote_video_output_dir, Path(all_match_merged_video_path).name
        )
        video_uploader.upload_video(all_match_merged_video_path, remote_video_output_path)
        return OutputVideoInfo(
            match_segments=all_match_segments,
            match_video_path=remote_video_output_path,
            total_size=all_match_merged_video_info.size,
            total_duration=all_match_merged_video_info.duration,
        )

    def _create_great_output_video_info(
        self,
        video_uploader: VideoUploader,
        great_match_video_path_list: list[str],
        great_match_segments: list[dict[ActionType, SegmentInfo]],
        great_match_video_info: list[VideoBaseInfo],
        remote_video_output_dir: str,
    ) -> OutputVideoInfo | None:
        with tempfile.TemporaryDirectory() as temp_dir:
            if great_match_video_path_list:
                zip_filename = (
                    os.path.splitext(os.path.basename(great_match_video_path_list[0]))[0]
                    + "_great_matches.zip"
                )
                zip_path = os.path.join(temp_dir, zip_filename)

                with zipfile.ZipFile(zip_path, "w") as zip_file:
                    for video_path in great_match_video_path_list:
                        zip_file.write(video_path, os.path.basename(video_path))

                remote_zip_file = path_utils.path_join(remote_video_output_dir, zip_filename)
                video_uploader.upload_video(zip_path, remote_zip_file)

                os.remove(zip_path)
                return OutputVideoInfo(
                    match_segments=great_match_segments,
                    match_video_path=remote_zip_file,
                    total_size=sum(video_info.size for video_info in great_match_video_info),
                    total_duration=sum(
                        video_info.duration for video_info in great_match_video_info
                    ),
                )
            return None

    def process_video_local(
        self,
        file_info: FileCreateInfo,
        input_path: str,
        sports_type: SportType,
        auto_clip_config: dict[str, Any] | None,
        progress_handler: ProgressHandler | None,
        cleanable_file_collection: CleanableFileCollection,
    ) -> VideoClipResult:
        if self.test_filesystem is not None and file_info.path is not None:
            filesystem = self.test_filesystem
            with timer("文件下载"):
                filesystem.download_file(file_info.path, input_path)
                if sports_type == SportType.PING_PONG:
                    video_clip_output_info: VideoClipOutputInfo = (
                        self.pingpong_auto_clipper.autoclip_video(
                            input_path,
                            auto_clip_config,
                            progress_handler,
                            cleanable_file_collection,
                        )
                    )
                elif sports_type == SportType.BADMINTON:
                    video_clip_output_info: VideoClipOutputInfo = (
                        self.badminton_auto_clipper.autoclip_video(
                            input_path,
                            auto_clip_config,
                            progress_handler,
                            cleanable_file_collection,
                        )
                    )

            video_uploader = VideoUploader(file_system=filesystem, client=self.http_client)
            remote_video_output_path = path_utils.path_join(
                self.remote_video_output_dir, datetime.datetime.now().strftime("%Y%m%d")
            )
            with timer("文件上传:"):
                remote_file: VideoClipResult = self._upload_and_create_result(
                    video_uploader, video_clip_output_info, remote_video_output_path
                )
        else:
            raise ValueError("test_filesystem is None")
        return remote_file

    def _send_message(self, message: VideoClipResultMessage) -> None:
        LOG.info(f"发送消息: {message}")
        self.http_client.post(
            url=ServerApi.AUTOCLIP_RESULT,
            content=message.model_dump_json(),
            headers={"Content-Type": "application/json"},
        )

    def _resend_remaining_messages(self) -> None:
        """将队列中剩余的消息重新发送到Kafka"""
        producer_config = {
            "bootstrap.servers": self.kafka_config.bootstrap_servers,
        }
        producer = Producer(producer_config)

        # 获取队列中所有剩余的消息
        remaining_messages: list[Message] = []
        while not self.message_queue.empty():
            try:
                msg = self.message_queue.get_nowait()
                remaining_messages.append(msg)
            except QueueEmpty:
                break

        if remaining_messages:
            LOG.info(f"发现 {len(remaining_messages)} 条未处理的消息，正在重新发送回Kafka...")

            # 重新发送消息回Kafka
            for msg in remaining_messages:
                try:
                    msg_json = msg.value()
                    producer.produce(
                        topic=self.handle_video_message_topic,
                        value=msg_json,
                        on_delivery=lambda err, msg: LOG.error(f"重新发送消息失败: {err}")
                        if err
                        else LOG.info(
                            f"消息重新发送成功: topic={msg.topic()}, "
                            f"partition={msg.partition()}, "
                            f"offset={msg.offset()}"
                        ),
                    )
                except Exception as e:
                    LOG.error(f"重新发送消息时发生错误: {e}")
                    LOG.error(traceback.format_exc())

            # 确保所有消息都已发送
            producer.flush()
            LOG.info("所有未处理的消息已重新发送到Kafka")

    def stop(self) -> None:
        self.running = False
        LOG.info("正在关闭Kafka消费者...")

        try:
            # 等待当前正在处理的消息完成
            self.message_queue.join()

            # 将队列中剩余的消息重新发送到Kafka
            self._resend_remaining_messages()

            if self.processing_thread and self.processing_thread.is_alive():
                self.processing_thread.join(timeout=30)
        except Exception as e:
            LOG.error(f"关闭Kafka消费者时发生错误: {e}")
            raise e
