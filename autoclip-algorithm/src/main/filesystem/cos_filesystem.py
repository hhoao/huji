import os
from typing import Any, override

from qcloud_cos import CosConfig, CosS3Client  # type: ignore

from src.main.config.config import S3Config
from src.main.filesystem.base_filesystem import S3FileSystem
from src.main.utils import string_utils


class COSFileSystem(S3FileSystem):
    def __init__(self, config: S3Config, root_path: str | None = None) -> None:
        super().__init__(config, root_path)

        cos_config: CosConfig = CosConfig(  # type: ignore
            Region=config.region,
            SecretId=config.access_key_id,
            SecretKey=config.access_key_secret,
        )
        self.client: CosS3Client = CosS3Client(cos_config)  # type: ignore

    @override
    def create_file(self, path: str, data: str | bytes) -> None:
        """创建文件"""
        self.client.put_object(Bucket=self.bucket_name, Body=data, Key=self.format_path(path))  # type: ignore

    @override
    def get_dir_files(
        self, oss_uri: str, delimiter: str = "", recursive: bool = False
    ) -> list[str]:
        """获取目录下的文件列表"""
        cos_key_list: list[str] = []
        if recursive:
            self.__get_dir_files_recursive(self.format_path(oss_uri), cos_key_list, delimiter)
        else:
            prefix: str = self.format_path(oss_uri) + "/"
            marker: str = ""

            while True:
                response: dict[str, Any] = self.client.list_objects(  # type: ignore
                    Bucket=self.bucket_name,
                    Prefix=prefix,
                    Delimiter=delimiter,
                    Marker=marker,
                    MaxKeys=1000,
                )

                contents: list[dict[str, Any]] = response.get("Contents", [])
                for obj in contents:
                    key: str = obj["Key"]
                    if key == prefix:
                        continue
                    cos_key_list.append(key)

                # 检查是否还有更多数据
                if response.get("IsTruncated") == "true":
                    marker = response.get("NextMarker", "")
                else:
                    break

        # 移除根路径前缀
        cos_key_list = [
            cos_key[len(self.root_path) :]
            for cos_key in cos_key_list
            if cos_key.startswith(self.root_path)
        ]
        return cos_key_list

    def __get_dir_files_recursive(
        self, prefix: str, file_list: list[str], delimiter: str = ""
    ) -> None:
        """递归获取目录下所有文件"""
        marker: str = ""

        while True:
            response: dict[str, Any] = self.client.list_objects(  # type: ignore
                Bucket=self.bucket_name,
                Prefix=prefix,
                Delimiter=delimiter,
                Marker=marker,
                MaxKeys=1000,
            )

            contents: list[dict[str, Any]] = response.get("Contents", [])
            for obj in contents:
                key: str = obj["Key"]
                if key == prefix:
                    continue
                file_list.append(key)

            # 处理子目录（如果有delimiter）
            common_prefixes: list[dict[str, str]] = response.get("CommonPrefixes", [])
            for prefix_info in common_prefixes:
                sub_prefix: str = prefix_info["Prefix"]
                self.__get_dir_files_recursive(sub_prefix, file_list, delimiter)

            # 检查是否还有更多数据
            if response.get("IsTruncated") == "true":
                marker = response.get("NextMarker", "")
            else:
                break

    @override
    def download_file(self, file_path: str, native_save_path: str) -> None:
        """下载文件到本地"""
        if string_utils.is_not_empty(os.path.dirname(native_save_path)):
            os.makedirs(os.path.dirname(native_save_path), exist_ok=True)

        # 检查文件是否存在
        response: dict[str, Any] = self.client.get_object(  # type: ignore
            Bucket=self.bucket_name, Key=self.format_path(file_path)
        )
        response["Body"].get_stream_to_file(native_save_path)

    @override
    def file_exists(self, file_path: str) -> bool:
        """检查文件是否存在"""
        try:
            self.client.head_object(Bucket=self.bucket_name, Key=self.format_path(file_path))  # type: ignore
            return True
        except Exception:
            return False

    @override
    def delete_file(self, file_path: str) -> None:
        """删除文件"""
        self.client.delete_object(Bucket=self.bucket_name, Key=self.format_path(file_path))  # type: ignore

    @override
    def upload_file(self, local_file_path: str, remote_file_path: str) -> str:
        """上传本地文件到COS"""
        dist: str = self.format_path(remote_file_path)
        with open(local_file_path, "rb") as f:
            self.client.put_object(Bucket=self.bucket_name, Body=f, Key=dist)  # type: ignore
        return dist

    @override
    def generate_url(self, key: str, second: int) -> str:
        """生成预签名URL"""
        response = self.client.get_presigned_download_url(  # type: ignore
            Bucket=self.bucket_name, Key=self.format_path(key), Expired=second
        )
        assert isinstance(response, str)
        return response
