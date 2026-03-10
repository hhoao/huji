from typing import Any

from src.main.config.config import DataSourceConfig
from src.main.database.mysql_client import MySQLDatabaseClient
from src.main.pojo.filesystem_config import (
    FileStorageEnum,
    LocalFileSystemConfigVO,
    S3FileSystemConfigVO,
)


class FileSystemConfigDao:
    def __init__(self, mysql_config: DataSourceConfig) -> None:
        self.client: MySQLDatabaseClient = MySQLDatabaseClient(mysql_config)

    def get_filesystem_config(
        self, config_id: int
    ) -> LocalFileSystemConfigVO | S3FileSystemConfigVO:
        sql: str = f"""
            SELECT storage, config FROM infra_file_config
            WHERE id = {config_id}
        """
        res: list[dict[str, Any]] = self.client.execute_sql_with_result(sql)
        if len(res) <= 0:
            raise Exception(f"文件系统配置不存在: {config_id}")

        row: dict[str, Any] = res[0]
        storage: int = int(row["storage"])
        if storage == FileStorageEnum.S3.value:
            s3_config: S3FileSystemConfigVO = S3FileSystemConfigVO(
                config_id, storage, str(row["config"])
            )
            return s3_config
        if storage == FileStorageEnum.LOCAL.value:
            local_config: LocalFileSystemConfigVO = LocalFileSystemConfigVO(
                config_id, storage, str(row["config"])
            )
            return local_config
        raise Exception(f"不支持的文件系统类型: {storage}")
