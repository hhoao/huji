from src.main.filesystem import load_filesystem
from src.main.logger import LOG
from src.main.utils.path_utils import get_resource
from src.test.base.test_base import TestCaseBase


class TestFileSystem(TestCaseBase):
    def _setup_internal(self):
        pass

    def test_download_file(self):
        self.fs = load_filesystem(self.config.filesystem_config.cos_config, "/video")
        self.fs.download_file("test.mp4", "test.mp4")

    def test_download_file2(self):
        self.fs = load_filesystem(self.config.filesystem_config.cos_config, "/")
        self.fs.download_file("video/test.mp4", "test.mp4")

    def test_generate_url(self):
        self.fs = load_filesystem(self.config.filesystem_config.cos_config, "/public")
        url = self.fs.generate_url("wcq_zb_.mp4", 60 * 60 * 24 * 3650)
        LOG.info(url)

    def test_generate_url_for_folder(self):
        self.fs = load_filesystem(self.config.filesystem_config.cos_config, "/")
        url = self.fs.generate_url("20250617/*", 60 * 60)
        LOG.info(url)

    def test_upload_file(self):
        self.fs = load_filesystem(self.config.filesystem_config.cos_config, "/video")
        file = get_resource("video_examples/test.mp4")
        self.fs.upload_file(file, "test1.mp4")
