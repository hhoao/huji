from src.main.config.config import (
    S3Config,
)
from src.main.filesystem.base_filesystem import FileSystem
from src.main.filesystem.cos_filesystem import COSFileSystem
from src.main.filesystem.oss_filesystem import OSSFileSystem


def load_filesystem(config: S3Config, root_dir: str = "/") -> FileSystem:
    if config.service == "oss":
        return OSSFileSystem(config, root_dir)
    if config.service == "cos":
        return COSFileSystem(config, root_dir)
    raise ValueError(f"Invalid service type: {config.service}")
