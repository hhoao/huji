import json
import os
import tempfile
import threading
from typing import Any, cast

from flask import Flask, Response, jsonify, request
from flask_cors import CORS

from src.main.config.config import DataSourceConfig, KafkaConfig, ServiceConfig
from src.main.core.badminton_auto_clipper import BadmintonAutoClipper
from src.main.core.pingpong_auto_clipper import PingPongAutoClipper
from src.main.filesystem.base_filesystem import FileSystem
from src.main.http.response import CommonResult
from src.main.logger import LOG
from src.main.pojo.video_clip_vo import ClipVideoByFileVO, ClipVideoByUrlVO, FileCreateInfo
from src.main.service.filesystem_service import FileSystemService
from src.main.service.message_service import MessageService
from src.main.service.video_clip_helper import generate_file_name
from src.main.utils import path_utils, preconditions
from src.main.utils.common_util import timer


class VideoEditService:
    def __init__(
        self,
        service_config: ServiceConfig,
        mysql_config: DataSourceConfig,
        kafka_config: KafkaConfig,
        pingpong_auto_clipper: PingPongAutoClipper,
        badminton_auto_clipper: BadmintonAutoClipper,
        http_client: Any,
    ) -> None:
        self.max_content_length: int = service_config.max_content_length
        self.video_save_tempfolder: str = tempfile.mkdtemp()
        self.allowed_extensions: set[str] = {"video/mp4", "mp4", "avi", "mov", "mkv"}
        self.pingpong_auto_clipper = pingpong_auto_clipper
        self.badminton_auto_clipper = badminton_auto_clipper
        self.app = Flask(__name__)
        self.host: str = service_config.host
        self.port: int = service_config.port
        self.debug: bool = service_config.debug
        self.remote_video_output_dir: str = service_config.remote_video_output_dir
        self.configure(self.app)

        self.file_system_client_service = FileSystemService(http_client)
        self.message_service = MessageService(
            service_config=service_config,
            kafka_config=kafka_config,
            pingpong_auto_clipper=pingpong_auto_clipper,
            badminton_auto_clipper=badminton_auto_clipper,
            http_client=http_client,
        )
        self.http_client = http_client

    def configure(self, app: Flask) -> None:
        CORS(app)

        app.config["MAX_CONTENT_LENGTH"] = self.max_content_length  # 最大500MB
        app.config["ALLOWED_EXTENSIONS"] = self.allowed_extensions

        # Register routes
        app.add_url_rule("/", view_func=self.index)
        app.add_url_rule("/api/video-clip/url", view_func=self.clip_video_url, methods=["POST"])
        app.add_url_rule("/api/video-clip/file", view_func=self.clip_video_file, methods=["POST"])
        app.register_error_handler(Exception, self.handle_all_exceptions)

    def index(self) -> Response:
        return jsonify(
            {
                "service": "Video Editing API",
                "version": "1.0.0",
                "status": "running",
                "endpoints": ["/api/clip-video"],
            }
        )

    def clip_video_url(self) -> Response | tuple[Response, int]:
        data = json.loads(str(request.data, encoding="utf-8"))
        file_info = ClipVideoByUrlVO(**data)

        input_filename = generate_file_name(file_info.path, file_info.file_type)
        input_path = os.path.join(self.video_save_tempfolder, input_filename)

        filesystem = self.file_system_client_service.get_filesystem(int(file_info.config_id))

        with timer("文件下载"):
            filesystem.download_file(file_info.path, input_path)

        return self.clip_video(filesystem, input_path)

    def clip_video_file(self) -> Response | tuple[Response, int]:
        if "file" not in request.files:
            return jsonify({"error": "未上传视频文件"}), 400

        form_data = request.form.to_dict()
        file_info = ClipVideoByFileVO(
            config_id=int(form_data["config_id"]),
            file_type=form_data["file_type"],
        )

        video_file = request.files["file"]
        if video_file.filename is None:
            return jsonify({"error": "文件名不能为空"}), 400

        preconditions.check_argument(self.allowed_file(file_info.file_type), "文件名不允许")

        input_filename = generate_file_name(video_file.filename, file_info.file_type)
        input_path = os.path.join(self.video_save_tempfolder, input_filename)

        video_file.save(input_path)

        filesystem = self.file_system_client_service.get_filesystem(int(file_info.config_id))

        return self.clip_video(filesystem, input_path)

    def handle_all_exceptions(self, error: Exception) -> Response:
        return jsonify(cast(dict[str, Any], CommonResult.error(exception=error)))

    def clip_video(self, filesystem: FileSystem, input_path: str) -> Response:
        output_info = ""
        try:
            output_info = self.pingpong_auto_clipper.autoclip_video(
                input_path,
                auto_clip_config={},
            ).all_match_merged_video_path

            remote_file = path_utils.path_join(
                self.remote_video_output_dir, os.path.basename(output_info)
            )
            remote_file = filesystem.upload_file(output_info, remote_file)
            url = filesystem.generate_url(remote_file, 60 * 60 * 60 * 24)

            return jsonify(
                cast(
                    dict[str, Any],
                    CommonResult.success(
                        FileCreateInfo(
                            config_id=int(filesystem.config_id),
                            path=remote_file,
                            name=os.path.basename(remote_file),
                            type="video/mp4",
                            size=os.path.getsize(output_info),
                            url=url,
                        )
                    ),
                )
            )
        finally:
            if os.path.exists(input_path):
                os.remove(input_path)
            if os.path.exists(output_info):
                os.remove(output_info)

    def start(self) -> None:
        LOG.info("视频剪辑服务启动")
        threading.Thread(target=self.message_service.start, name="message_service").start()
        self.app.run(host=self.host, port=self.port, debug=self.debug)

    def stop(self) -> None:
        self.message_service.stop()

    def allowed_file(self, mimetype: str) -> bool:
        return mimetype in self.allowed_extensions
