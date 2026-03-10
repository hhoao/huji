"""
FTP文件系统实现
"""

import os
from ftplib import FTP
from typing import override

import tenacity

from src.main.filesystem.base_filesystem import FileSystem
from src.main.logger import LOG
from src.main.utils.common_util import retry_all_methods


@retry_all_methods
class FTPFileSystem(FileSystem):
    @override
    def create_file(self, path: str, data: str | bytes) -> None:
        pass

    @override
    def generate_url(self, key: str, second: int) -> str:
        return ""

    @override
    def upload_file(self, local_file_path: str, remote_file_path: str) -> str:
        return ""

    def __init__(self, host: str, port: int, username: str, password: str, root: str = "/") -> None:
        super().__init__(root, -1)
        self.host: str = host
        self.port: int = port
        self.username: str = username
        self.password: str = password
        self.ftp: FTP | None = None

    def _ensure_connected(self) -> None:
        """确保FTP连接已建立"""
        connect: bool = True
        if not self.ftp:
            connect = False
        if self.ftp:
            try:
                self.ftp.pwd()
            except Exception:
                connect = False

        if not connect:
            try:
                self.ftp = FTP()
                self.ftp.connect(self.host, self.port)
                self.ftp.login(self.username, self.password)
                self.ftp.encoding = "utf-8"
                self.ftp.timeout = 60
                LOG.info(f"Successfully connected to FTP server {self.host}:{self.port}")
            except Exception as e:
                LOG.error(f"Failed to connect to FTP server: {e!s}")
                raise

    @override
    def get_dir_files(
        self, oss_uri: str, delimiter: str = "", recursive: bool = False
    ) -> list[str]:
        """获取目录下的文件列表

        Args:
            oss_uri: FTP目录路径
            delimiter: 分隔符（FTP不使用）
            recursive: 是否递归获取子目录

        Returns:
            list[str]: 文件路径列表
        """
        self._ensure_connected()
        if not self.ftp:
            return []
        try:
            self.ftp.cwd(oss_uri)
            files: list[str] = []
            self.ftp.dir("", files.append)

            # 解析文件列表
            file_paths: list[str] = []
            for file_info in files:
                # 解析FTP LIST命令的输出
                parts: list[str] = file_info.split()
                if len(parts) >= 9:
                    file_name: str = parts[8]
                    file_path: str = os.path.join(oss_uri, file_name)
                    file_paths.append(file_path)

                    # 如果是目录且需要递归，则递归获取子目录文件
                    if recursive and file_info.startswith("d"):
                        sub_files: list[str] = self.get_dir_files(file_path, delimiter, recursive)
                        file_paths.extend(sub_files)

            return file_paths
        except Exception as e:
            LOG.error(f"Failed to list files in {oss_uri}: {e!s}")
            return []

    @tenacity.retry(stop=tenacity.stop_after_attempt(3), wait=tenacity.wait_fixed(2))
    @override
    def download_file(self, file_path: str, native_save_path: str) -> None:
        self._ensure_connected()
        if not self.ftp:
            return
        os.makedirs(os.path.dirname(native_save_path), exist_ok=True)

        with open(native_save_path, "wb") as f:
            self.ftp.retrbinary(f"RETR {file_path}", f.write)

    @override
    def file_exists(self, file_path: str) -> bool:
        self._ensure_connected()
        if not self.ftp:
            return False
        try:
            # 尝试获取文件大小，如果文件不存在会抛出异常
            self.ftp.size(file_path)
            return True
        except BrokenPipeError as e:
            raise e
        except Exception:
            return False

    @override
    def delete_file(self, file_path: str) -> None:
        """删除FTP文件

        Args:
            file_path: FTP文件路径
        """
        self._ensure_connected()
        if not self.ftp:
            return
        try:
            self.ftp.delete(file_path)
        except Exception as e:
            LOG.error(f"Failed to delete file {file_path}: {e!s}")
