import os
from typing import cast, override

import oss2  # type: ignore

from src.main.config.config import S3Config
from src.main.filesystem.base_filesystem import S3FileSystem
from src.main.utils import string_utils


class OSSFileSystem(S3FileSystem):
    def __init__(self, config: S3Config, root_path: str | None = None) -> None:  # type: ignore
        super().__init__(config, root_path)
        self.bucket = oss2.Bucket(self.auth, self.region, self.bucket_name, connect_timeout=60)  # type: ignore

    @override
    def create_file(self, path: str, data: str | bytes) -> None:
        self.bucket.put_object(self.format_path(path), data)  # type: ignore

    @override
    def get_dir_files(
        self, oss_uri: str, delimiter: str = "", recursive: bool = False
    ) -> list[str]:
        oss_key_list: list[str] = []
        if recursive:
            self.__get_dir_files_recursive(self.format_path(oss_uri), oss_key_list, delimiter)
        else:
            prefix: str = self.format_path(oss_uri) + "/"
            for obj in oss2.ObjectIterator(self.bucket, prefix=prefix, delimiter=delimiter):  # type: ignore
                key = cast(str, obj.key)  # type: ignore
                if key == prefix:
                    continue
                oss_key_list.append(key)
        oss_key_list = [oss_key[len(self.root_path) :] for oss_key in oss_key_list]
        return oss_key_list

    def __get_dir_files_recursive(
        self, prefix: str, file_list: list[str], delimiter: str = ""
    ) -> None:
        for obj in oss2.ObjectIterator(self.bucket, prefix=prefix, delimiter=delimiter):  # type: ignore
            key = cast(str, obj.key)  # type: ignore
            if key == prefix:
                continue
            if cast(bool, obj.is_prefix()):  # type: ignore
                self.__get_dir_files_recursive(key, file_list, delimiter=delimiter)
            else:
                file_list.append(key)

    @override
    def download_file(self, file_path: str, native_save_path: str) -> None:
        if string_utils.is_not_empty(os.path.dirname(native_save_path)):
            os.makedirs(os.path.dirname(native_save_path), exist_ok=True)
        self.bucket.get_object_to_file(self.format_path(file_path), native_save_path)  # type: ignore

    @override
    def file_exists(self, file_path: str) -> bool:
        return cast(bool, self.bucket.object_exists(self.format_path(file_path)))  # type: ignore

    @override
    def delete_file(self, file_path: str) -> None:
        self.bucket.delete_object(self.format_path(file_path))  # type: ignore

    @override
    def upload_file(self, local_file_path: str, remote_file_path: str) -> str:
        output_file: str = self.format_path(remote_file_path)
        self.bucket.put_object_from_file(self.format_path(remote_file_path), local_file_path)  # type: ignore
        return output_file

    def copy_file(self, source: str, target: str) -> None:
        self.bucket.copy_object(self.bucket.bucket_name, self.format_path(source), target)  # type: ignore

    @override
    def generate_url(self, key: str, second: int) -> str:
        return cast(str, self.bucket.sign_url("GET", self.format_path(key), second))  # type: ignore
