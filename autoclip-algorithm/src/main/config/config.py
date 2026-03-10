"""
Configuration management

用法:
    1. 加载主配置:
        config = load_config()  # 默认从 src/resources 加载
        config = load_config("/path/to/config")

    2. 配置来源优先级 (高到低):
        - 环境变量 (key 中 . 替换为 _，如 autoclip_service_config_common_workers)
        - application_{env}.yml (由 env 决定，默认 dev)
        - application.yml

    3. 访问子配置:
        config.auto_clip_config.ping_pong
        config.datasource_config.mysql
        config.large_model_service_config.models["ping_pong_singles_profession"]

    4. 自定义子配置 (需 ConfigContext):
        ctx = ConfigContext(config=dict_data, common_config=common, prefix="xxx", jasypt=jasypt)
        my_config = MyConfig(ctx)

    5. 敏感值加密: 配置中 ENC(密文) 格式的值会由 Jasypt 解密，需设置 JASYPT_PASSWORD 环境变量
"""

import os
import re
from abc import ABC, abstractmethod
from pathlib import Path
from typing import Any, TypeVar

from ruamel.yaml import YAML

from src import CONFIG_PATH
from src.main.constant.autoclip_constant import (
    EndpointInfo,
    MatchType,
    ModeEnum,
)
from src.main.constant.common_constant import JobType
from src.main.logger import LOG, configure
from src.main.utils import filesystem_utils, path_utils, string_utils
from src.main.utils.jasypt4py import Jasypt4py


pattern = re.compile(r"ENC\((.*)[)]", re.S)


T = TypeVar("T")


debug: bool = False


class ConfigContext:
    def __init__(
        self,
        config: object | None = None,
        common_config: object = None,
        prefix: str = "",
        jasypt: Jasypt4py | None = None,
        pure: bool = False,
    ):
        self.config = config
        self.common_config = common_config
        self.prefix = prefix
        self.jasypt = jasypt
        self.pure = pure


class SecurityConfig:
    def __init__(self, config_context: ConfigContext | None):
        if config_context is None:
            raise ValueError("config_context is None")
        self._prefix = config_context.prefix
        self._config = config_context.config
        self._common_config = config_context.common_config
        self._jasypt = config_context.jasypt

    def _get_value(self, key: str, default_value: T | None = None, allow_none: bool = False) -> T:  # type: ignore
        full_key = (self._prefix + "." + key) if not string_utils.is_empty(self._prefix) else key
        env_key = (full_key.replace(".", "_")) if not string_utils.is_empty(self._prefix) else key
        value = os.getenv(env_key)
        if value is None:
            env_key = full_key
            value = os.getenv(env_key)
        if value is None:
            value = self._get_value_from_config(key)
        if value is None:
            value = self._get_value_from_common_config(key)
        if value is None:
            LOG.warning(
                f"Configuration '{full_key}' is not set in environment or config file,"
                f" use default value {default_value} instead."
            )
            value = default_value

        if value is None and not allow_none and default_value is not None:
            raise ValueError(f"Key {key} not has default value, and value is None")

        LOG.info(f"{full_key}: {value}")

        if self._jasypt is not None and value is not None and value != "":
            result = re.findall(pattern, str(value))
            if len(result) > 0:
                value = self._jasypt.decrypt(result[0].encode("utf-8")).decode("utf-8")

        return value  # type: ignore

    def _get_value_from_config(self, key: str) -> object | None:
        if self._config is not None and key in self._config:  # type: ignore
            return self._config[key]  # type: ignore
        return None

    def _get_sub_config_context(self, prefix: str) -> "ConfigContext":
        return ConfigContext(
            self._get_value_from_config(prefix),
            self._get_value_from_common_config(prefix),
            (self._prefix + "." + prefix) if not string_utils.is_empty(self._prefix) else prefix,
            self._jasypt,
        )

    def _get_value_from_common_config(self, key: str) -> object | None:
        if self._common_config is not None and key in self._common_config:  # type: ignore
            return self._common_config[key]  # type: ignore
        return None


class DataSourceConfig(SecurityConfig):
    def __init__(self, config_context: ConfigContext):
        super().__init__(config_context)
        self.password = str(self._get_value("password"))
        self.type = str(self._get_value("type"))
        self.user = str(self._get_value("user"))
        self.database = str(self._get_value("database"))
        self.port: int = self._get_value("port")
        self.host = str(self._get_value("host"))
        self.cluster: str | None = self._get_value("cluster", None)
        self.connection_count = int(self._get_value("connection_count", os.cpu_count() or 8))


class DataSourcesConfig(SecurityConfig):
    def __init__(self, config_context: ConfigContext):
        super().__init__(config_context)
        self.mysql = DataSourceConfig(self._get_sub_config_context("mysql"))


class FileSystemConfig(SecurityConfig, ABC):
    def __init__(self, config_context: ConfigContext) -> None:
        super().__init__(config_context)
        self.type: str | None = None

    @abstractmethod
    def get_type(self) -> str:
        pass


class FTPConfig(FileSystemConfig):
    def get_type(self) -> str:
        return "ftp"

    def __init__(self, config_context: ConfigContext) -> None:
        super().__init__(config_context)
        self.host: str = str(self._get_value("host"))
        self.port: int = int(self._get_value("port", 21))
        self.username: str = str(self._get_value("username"))
        self.password: str = str(self._get_value("password"))


class S3Config(FileSystemConfig):
    def get_type(self) -> str:
        return self.service

    def __init__(self, config_context: ConfigContext) -> None:
        super().__init__(config_context)
        if config_context.pure:
            return
        endpoint: str = str(self._get_value("endpoint"))
        res: EndpointInfo = filesystem_utils.parse_endpoint(endpoint)
        self.service: str = res.service
        self.region: str = res.region
        self.provider: str = res.provider
        self.access_key_id: str = str(self._get_value("access_key_id"))
        self.access_key_secret: str = str(self._get_value("access_key_secret"))
        self.bucket_name: str = str(self._get_value("bucket_name"))
        self.config_id: int = self._get_value("config_id", -1)


class FileSystemsConfig(SecurityConfig):
    def __init__(self, config_context: ConfigContext):
        super().__init__(config_context)
        self.cos_config = S3Config(self._get_sub_config_context("cos"))


class CommonAutoClipOptions(SecurityConfig):
    def __init__(self, config_context: ConfigContext):
        super().__init__(config_context)
        cpu_count = os.cpu_count()
        if cpu_count is None:
            cpu_count = 8
        else:
            cpu_count = cpu_count - 4
        self.workers = self._get_value("workers", cpu_count)
        self.split_count = self._get_value("split_size", 1200)
        self.frame_interval: int = self._get_value("frame_interval", None)

        self.output_dir = path_utils.get_project_path(self._get_value("output_dir"))
        self.cache_path = path_utils.get_project_path(self._get_value("cache_path"))
        self.debug_clip_frame_output_dir: str | None = self._get_value(
            "debug_clip_frame_output_dir", None
        )
        if string_utils.is_not_empty(self.debug_clip_frame_output_dir):
            self.debug_clip_frame_output_dir = path_utils.get_project_path(
                self.debug_clip_frame_output_dir
            )


class PingPongAutoClipOptions(SecurityConfig):
    def __init__(self, config_context: ConfigContext):
        super().__init__(config_context)
        self.is_ignore_playback: bool = self._get_value("is_ignore_playback", True)
        self.fireball_max_seconds = self._get_value("fireball_max_seconds", 3.0)
        self.reserve_tail_seconds = self._get_value("reserve_tail_seconds", 1.0)
        self.reserve_header_seconds = self._get_value("reserve_header_seconds", 0.0)

        self.minimum_duration_single_round: float = self._get_value(
            "minimum_duration_single_round", 2.0
        )
        self.minimum_duration_great_ball: float = self._get_value(
            "minimum_duration_great_ball", 10.0
        )
        self.singles_model: str = self._get_value("models")["singles"]
        self.threshold_count: int = self._get_value("threshold_count", None)


class BadmintonAutoClipOptions(SecurityConfig):
    def __init__(self, config_context: ConfigContext):
        super().__init__(config_context)
        self.mode: ModeEnum = self._get_value("mode", ModeEnum.BACKEND_CLIP)
        self.match_type: MatchType = self._get_value("match_type", MatchType.SINGLES_MATCH)
        self.great_ball_editing: bool = self._get_value("great_ball_editing", True)
        self.is_ignore_playback: bool = self._get_value("is_ignore_playback", True)
        self.reserve_header_seconds = self._get_value("reserve_header_seconds", 1.0)
        self.reserve_tail_seconds = self._get_value("reserve_tail_seconds", 1.0)

        self.minimum_duration_single_round: float = self._get_value(
            "minimum_duration_single_round", 2.0
        )
        self.minimum_duration_great_ball: float = self._get_value(
            "minimum_duration_great_ball", 10.0
        )
        self.singles_model: str = self._get_value("models")["singles"]
        self.doubles_model: str = self._get_value("models")["doubles"]
        self.threshold_count: int = self._get_value("threshold_count", None)


class AutoClipServiceConfig(SecurityConfig):
    def __init__(self, config_context: ConfigContext):
        super().__init__(config_context)

        self.ping_pong: PingPongAutoClipOptions = PingPongAutoClipOptions(
            self._get_sub_config_context("ping_pong")
        )
        self.badminton: BadmintonAutoClipOptions = BadmintonAutoClipOptions(
            self._get_sub_config_context("badminton")
        )

        self.common_options: CommonAutoClipOptions = CommonAutoClipOptions(
            self._get_sub_config_context("common")
        )


class ModelConfig(SecurityConfig):
    def __init__(self, config_context: ConfigContext) -> None:
        super().__init__(config_context)
        self.predict_model_path: str = path_utils.get_project_path(
            self._get_value("predict_model_path")
        )
        self.train_model_path: str = path_utils.get_project_path(
            self._get_value("train_model_path")
        )
        self.train_dataset_path: str = path_utils.get_project_path(
            self._get_value("train_dataset_path")
        )
        self.train_output_path: str = path_utils.get_project_path(
            self._get_value("train_output_path")
        )
        self.total_dataset_path: str = path_utils.get_project_path(
            self._get_value("total_dataset_path")
        )


class LargeModelServiceConfig(SecurityConfig):
    def __init__(self, config_context: ConfigContext):
        super().__init__(config_context)
        self.models: dict[str, ModelConfig] = {}
        models: dict[str, object] = self._get_value("models")
        for model in models:
            self.models[model] = ModelConfig(ConfigContext(config=models[model]))
        self.train_model_name: str = self._get_value("train_model_name")
        self.debug = self._get_value("debug", False)


class KafkaConfig(SecurityConfig):
    def __init__(self, config_context: ConfigContext):
        super().__init__(config_context)
        self.bootstrap_servers: str = self._get_value("bootstrap_servers")
        self.consumer_group: str = self._get_value("consumer_group")
        self.auto_offset_reset: bool = self._get_value("auto_offset_reset")


class ServiceConfig(SecurityConfig):
    def __init__(self, config_context: ConfigContext):
        super().__init__(config_context)
        self.handle_video_message_topic: str = self._get_value(
            "handle_video_message_topic",
        )
        self.video_result_processor_url: str = self._get_value("video_result_processor_url")
        self.remote_video_output_dir: str = path_utils.get_project_path(
            self._get_value("remote_video_output_dir")
        )
        self.max_content_length = self._get_value("max_content_length", 2000 * 1024 * 1024)
        self.host = self._get_value("host", "localhost")
        self.port = self._get_value("port", 8080)
        self.debug = self._get_value("debug", False)
        self.async_process_message = self._get_value("async_process_message", False)


class InternalHttpConfig(SecurityConfig):
    def __init__(self, config_context: ConfigContext):
        super().__init__(config_context)
        self.base_url = self._get_value("base_url", "localhost")
        self.access_token: str = self._get_value("access_token")


class InternalConfig(SecurityConfig):
    def __init__(self, config_context: ConfigContext):
        super().__init__(config_context)
        self.http = InternalHttpConfig(self._get_sub_config_context("http"))


class Config(SecurityConfig):
    def __init__(self, config_context: ConfigContext, config_path: str) -> None:
        super().__init__(config_context)

        env: str = self._get_value("env", "dev")
        self.env = env
        config_file: str = config_path + f"/application_{env}.yml"
        if Path(config_file).exists():
            with open(config_file) as file:
                yaml = YAML(typ="safe", pure=True)
                config: dict[str, Any] = yaml.load(file)  # type: ignore
                self._config = config  # type: ignore

        global debug
        debug = self._get_value("debug", False)

        self.logger_level: str = self._get_value("logger_level")
        configure(self.logger_level)

        self._jasypt_password: str | None = self._get_value(
            "JASYPT_PASSWORD", None, allow_none=True
        )
        if string_utils.is_not_empty(self._jasypt_password):
            self._jasypt: Jasypt4py | None = Jasypt4py(self._jasypt_password.encode("utf-8"))
        else:
            self._jasypt = None

        self.job_type: JobType = JobType.from_str(self._get_value("job_type"))
        self.large_model_service_config: LargeModelServiceConfig = LargeModelServiceConfig(
            self._get_sub_config_context("large_model")
        )

        self.auto_clip_config: AutoClipServiceConfig = AutoClipServiceConfig(
            self._get_sub_config_context("autoclip_service_config")
        )
        self.service_config: ServiceConfig = ServiceConfig(self._get_sub_config_context("service"))
        self.filesystem_config: FileSystemsConfig = FileSystemsConfig(
            self._get_sub_config_context("filesystem")
        )
        self.datasource_config: DataSourcesConfig = DataSourcesConfig(
            self._get_sub_config_context("datasource")
        )
        self.kafka_config: KafkaConfig = KafkaConfig(self._get_sub_config_context("kafka"))
        self.internal: InternalConfig = InternalConfig(self._get_sub_config_context("internal"))


def load_config(config_path: str = CONFIG_PATH) -> Config:
    common_config_file: str = config_path + "/application.yml"
    if Path(common_config_file).exists():
        with open(common_config_file) as file:
            yaml = YAML(typ="safe", pure=True)
            common_config: dict[str, Any] = yaml.load(file)  # type: ignore
            return Config(ConfigContext(None, common_config, "", None), config_path)  # type: ignore
    raise FileNotFoundError(f"Common config file not found: {common_config_file}")
