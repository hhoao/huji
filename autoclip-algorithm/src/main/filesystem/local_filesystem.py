import os
import shutil
from typing import override
from urllib.parse import urljoin

from src.main.filesystem.base_filesystem import FileSystem


class LocalFileSystem(FileSystem):
    def __init__(self, root_path: str, config_id: int) -> None:
        super().__init__(root_path, config_id)
        if not os.path.exists(self.root_path):
            os.makedirs(self.root_path, exist_ok=True)
        self.domain: str = "file://localhost"

    @override
    def create_file(self, path: str, data: str | bytes) -> None:
        """创建文件"""
        full_path: str = self.format_path(path)

        # 确保目录存在
        dir_path: str = os.path.dirname(full_path)
        if dir_path and not os.path.exists(dir_path):
            os.makedirs(dir_path, exist_ok=True)

        # 写入文件
        if isinstance(data, str):
            with open(full_path, "w", encoding="utf-8") as f:
                f.write(data)
        else:
            with open(full_path, "wb") as f:
                f.write(data)

    @override
    def get_dir_files(
        self, oss_uri: str, delimiter: str = "", recursive: bool = False
    ) -> list[str]:
        """获取目录下的文件列表"""
        full_dir_path: str = self.format_path(oss_uri)
        file_list: list[str] = []

        if not os.path.exists(full_dir_path) or not os.path.isdir(full_dir_path):
            return file_list

        if recursive:
            self._get_dir_files_recursive(full_dir_path, file_list, delimiter)
        else:
            try:
                for item in os.listdir(full_dir_path):
                    item_path: str = os.path.join(full_dir_path, item)
                    if os.path.isfile(item_path):
                        # 返回相对于根路径的路径
                        relative_path: str = os.path.relpath(item_path, self.root_path)
                        if delimiter == "" or delimiter not in relative_path:
                            file_list.append(relative_path.replace("\\", "/"))
            except PermissionError:
                pass

        return file_list

    def _get_dir_files_recursive(self, dir_path: str, file_list: list[str], delimiter: str) -> None:
        """递归获取目录下的所有文件"""
        try:
            for item in os.listdir(dir_path):
                item_path: str = os.path.join(dir_path, item)
                if os.path.isfile(item_path):
                    # 返回相对于根路径的路径
                    relative_path: str = os.path.relpath(item_path, self.root_path)
                    if delimiter == "" or delimiter not in relative_path:
                        file_list.append(relative_path.replace("\\", "/"))
                elif os.path.isdir(item_path):
                    self._get_dir_files_recursive(item_path, file_list, delimiter)
        except PermissionError:
            pass

    @override
    def download_file(self, file_path: str, native_save_path: str) -> None:
        """下载文件"""
        full_path: str = self.format_path(file_path)
        if not os.path.exists(full_path):
            raise FileNotFoundError(f"File not found: {full_path}")

        # 确保目标目录存在
        save_dir: str = os.path.dirname(native_save_path)
        if save_dir and not os.path.exists(save_dir):
            os.makedirs(save_dir, exist_ok=True)

        shutil.copy2(full_path, native_save_path)

    @override
    def file_exists(self, file_path: str) -> bool:
        """检查文件是否存在"""
        full_path: str = self.format_path(file_path)
        return os.path.exists(full_path) and os.path.isfile(full_path)

    @override
    def delete_file(self, file_path: str) -> None:
        """删除文件"""
        full_path: str = self.format_path(file_path)
        if os.path.exists(full_path):
            os.remove(full_path)

    @override
    def upload_file(self, local_file_path: str, remote_file_path: str) -> str:
        """上传文件"""
        if not os.path.exists(local_file_path):
            raise FileNotFoundError(f"Local file not found: {local_file_path}")

        full_remote_path: str = self.format_path(remote_file_path)
        # 确保目标目录存在
        remote_dir: str = os.path.dirname(full_remote_path)
        if remote_dir and not os.path.exists(remote_dir):
            os.makedirs(remote_dir, exist_ok=True)

        shutil.copy2(local_file_path, full_remote_path)
        return remote_file_path

    def copy_file(self, source: str, target: str) -> None:
        """复制文件"""
        source_path: str = self.format_path(source)
        target_path: str = self.format_path(target)
        shutil.copy2(source_path, target_path)

    def get_file_size(self, file_path: str) -> int:
        """获取文件大小"""
        full_path: str = self.format_path(file_path)
        return os.path.getsize(full_path)

    def get_file_modified_time(self, file_path: str) -> float:
        """获取文件修改时间"""
        full_path: str = self.format_path(file_path)
        if os.path.exists(full_path) and os.path.isfile(full_path):
            return os.path.getmtime(full_path)
        return 0.0

    @override
    def generate_url(self, key: str, second: int) -> str:
        """生成文件访问URL"""
        return urljoin(self.domain, key)
