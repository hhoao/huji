import os
from pathlib import Path


ROOT_PATH = str(Path.resolve(Path(os.path.dirname(__file__)).parent))
CONFIG_PATH = ROOT_PATH + "/src/resources"
MAIN_PATH = ROOT_PATH + "/src/main"
MAIN_SRC = MAIN_PATH + "/python"
TEST_PATH = ROOT_PATH + "/src/test"
TEST_SRC = TEST_PATH + "/python"

RESOURCES_PATH = ROOT_PATH + "/src/resources"
