from src.main.dao.filesystem_config_dao import FileSystemConfigDao
from src.test.base.test_base import TestCaseBase


class MyTestCase(TestCaseBase):
    def _setup_internal(self):
        self.dao = FileSystemConfigDao(self.config.datasource_config.mysql)

    def test_get_file_config(self):
        file_config = self.dao.get_filesystem_config(32)
        print(file_config)
