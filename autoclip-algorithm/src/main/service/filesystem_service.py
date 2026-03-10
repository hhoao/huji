from httpx import Client

from src.main.config.config import ConfigContext, S3Config
from src.main.constant.server_api import ServerApi
from src.main.filesystem import load_filesystem
from src.main.filesystem.base_filesystem import FileSystem
from src.main.filesystem.local_filesystem import LocalFileSystem
from src.main.pojo.filesystem_config import (
    FileStorageEnum,
    FileSystemConfigVO,
    LocalFileSystemConfigVO,
    S3FileSystemConfigVO,
)
from src.main.utils import filesystem_utils


class FileSystemService:
    def __init__(self, http_client: Client) -> None:
        self.internal_client = http_client

    def get_filesystem(self, config_id: int) -> FileSystem:
        filesystem_config = self.get_filesystem_config(config_id)
        if isinstance(filesystem_config, S3FileSystemConfigVO):
            config = S3Config(ConfigContext(pure=True))
            res = filesystem_utils.parse_endpoint(filesystem_config.endpoint)
            config.service = res.service
            config.region = res.region
            config.provider = res.provider
            config.access_key_id = filesystem_config.access_key
            config.access_key_secret = filesystem_config.access_secret
            config.bucket_name = filesystem_config.bucket
            config.config_id = filesystem_config.id
            filesystem = load_filesystem(config)
            return filesystem
        if isinstance(filesystem_config, LocalFileSystemConfigVO):
            return LocalFileSystem(config_id=config_id, root_path=filesystem_config.base_path)
        raise Exception(f"Not implement filesystem {config_id}")

    def get_filesystem_config(self, config_id: int) -> FileSystemConfigVO:
        res = self.internal_client.get(ServerApi.INFR_FILE_CONFIG_GET, params={"id": config_id})
        data = res.json()

        storage: int = int(data["storage"])
        if storage == FileStorageEnum.S3.value:
            s3_config: S3FileSystemConfigVO = S3FileSystemConfigVO(
                config_id, storage, str(data["config"])
            )
            return s3_config
        if storage == FileStorageEnum.LOCAL.value:
            local_config: LocalFileSystemConfigVO = LocalFileSystemConfigVO(
                config_id, storage, str(data["config"])
            )
            return local_config
        raise Exception(f"Not implement filesystem {config_id}")
