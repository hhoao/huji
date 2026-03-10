from src.main.http.internal_http import InternalHttp
from src.main.service.filesystem_service import FileSystemService
from src.test.base.test_base import TestCaseBase


class TestFileSystemService(TestCaseBase):
    def _setup_internal(self):
        self.http_client = InternalHttp(self.config.internal.http).client
        self.service = FileSystemService(self.http_client)

    def test_get_file_config(self):
        filesystem = self.service.get_filesystem(32)
        filesystem.download_file(
            "20250612/8c4d3a0f30bdebd61a04c5be8bd2177a_raw_1749734042753.mp4", "test.mp4"
        )
