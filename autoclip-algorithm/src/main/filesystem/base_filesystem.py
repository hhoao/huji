from abc import ABC, abstractmethod

import oss2  # type: ignore

from src.main.config.config import S3Config
from src.main.utils import path_utils


s3_prefix: list[str] = ["oss://", "cos://"]


def parse_uri(s3_uri: str) -> tuple[str, str]:
    """
    解析 OSS URI，提取 Bucket 名称和文件路径。

    示例：
    - 输入："oss://bucket-f_name/path/to/object"
    cos://blog-1258599900/video/test.mp4
    :param s3_uri: OSS URI，格式为 oss://bucket-f_name/path/to/object
    :return: 返回一个元组 (bucket_name, object_path)
    """

    is_s3: bool = False
    for prefix in s3_prefix:
        if s3_uri.startswith(prefix):
            is_s3 = True
            break
    if not is_s3:
        raise ValueError("Invalid OSS URI: must start with '[s3_prefix]://'")

    s3_uri = s3_uri[6:]

    slash_index: int = s3_uri.find("/")

    if slash_index == -1:
        bucket_name: str = s3_uri
        object_path: str = ""
    else:
        bucket_name = s3_uri[:slash_index]
        object_path = s3_uri[slash_index + 1 :]

    return bucket_name, object_path


class FileSystem:
    def __init__(self, root_path: str, config_id: int) -> None:
        self.root_path: str = root_path
        self.config_id: int = config_id

    @abstractmethod
    def create_file(self, path: str, data: str | bytes) -> None:
        pass

    def get_root_dir(self) -> str:
        return self.root_path

    @abstractmethod
    def get_dir_files(
        self, oss_uri: str, delimiter: str = "", recursive: bool = False
    ) -> list[str]:
        pass

    @abstractmethod
    def download_file(self, file_path: str, native_save_path: str) -> None:
        pass

    @abstractmethod
    def file_exists(self, file_path: str) -> bool:
        pass

    @abstractmethod
    def delete_file(self, file_path: str) -> None:
        pass

    @abstractmethod
    def upload_file(self, local_file_path: str, remote_file_path: str) -> str:
        pass

    def format_path(self, path: str) -> str:
        return path_utils.path_join(self.root_path, path)

    @abstractmethod
    def generate_url(self, key: str, second: int) -> str:
        pass


class S3FileSystem(FileSystem, ABC):
    def __init__(self, config: S3Config, root_path: str | None = None) -> None:
        super().__init__(root_path or "", config.config_id)
        self.auth = oss2.Auth(config.access_key_id, config.access_key_secret)  # type: ignore
        self.region: str = config.region
        self.bucket_name: str = config.bucket_name
