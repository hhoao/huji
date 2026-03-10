from __future__ import annotations

import sys

import loguru
from loguru import logger

from src import ROOT_PATH


_logger: loguru.Logger | None = None


def configure(level: str = "INFO"):
    global _logger
    if _logger is None:
        _logger = logger
    _logger.remove()
    _logger.add(ROOT_PATH + "/output/logs/debug.log", level="DEBUG")
    _logger.add(ROOT_PATH + "/output/logs/info.log", level="INFO")
    _logger.add(ROOT_PATH + "/output/logs/warn.log", level="WARNING")
    _logger.add(ROOT_PATH + "/output/logs/error.log", level="ERROR")
    _logger.add(sys.stdout, level=level)


def get_logger(level: str = "INFO") -> loguru.Logger:
    global _logger
    if _logger is None:
        configure(level)
    if _logger is None:
        raise RuntimeError("Logger has not been configured. Call configure() first.")
    return _logger


LOG = get_logger()
