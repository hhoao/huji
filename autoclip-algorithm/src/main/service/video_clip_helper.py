import os
import time


def generate_file_name(file: str, file_type: str) -> str:
    # video/mp4
    file_type = file_type.split("/")[-1]
    filename_with_ext = os.path.basename(file)
    filename, _ = os.path.splitext(filename_with_ext)

    input_filename = f"{filename}-{int(round(time.time() * 1000))}.{file_type}"
    return input_filename
