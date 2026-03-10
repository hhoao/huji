from enum import Enum


class JobType(Enum):
    SERVICE = "service"
    TRAIN_MODEL = "train_model"

    @staticmethod
    def from_str(value: str) -> "JobType":
        return JobType[value.upper()]
