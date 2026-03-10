import unittest
from abc import abstractmethod
from typing import override

from src.main.config.config import Config, load_config


class TestCaseBase(unittest.TestCase):
    @override
    def setUp(self) -> None:
        self.config: Config = load_config()
        self._setup_internal()

    @abstractmethod
    def _setup_internal(self) -> None:
        pass


if __name__ == "__main__":
    unittest.main()
