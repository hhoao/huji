from src.main.pojo.filesystem_config import FileStorageEnum
from src.test.base.test_base import TestCaseBase


class TestFileSystem(TestCaseBase):
    def _setup_internal(self):
        pass

    def test_request(self):
        testEnum = FileStorageEnum(20)
        print(testEnum)
