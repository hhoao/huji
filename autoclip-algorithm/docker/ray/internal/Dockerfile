# 使用NVIDIA官方的CUDA镜像作为基础镜像
FROM rayproject/ray:2.41.0-py312-gpu

RUN sudo apt update && \
    sudo apt-get install -y \
    wget \
    curl \
    build-essential \
    ffmpeg

RUN pip install ultralytics~=8.3.130 -i https://mirrors.aliyun.com/pypi/simple/

RUN pip install opencv-python~=4.11.0.86 \
    ruamel.yaml==0.18.10 \
    pycryptodome~=3.22.0 \
    tenacity~=9.1.2 \
    httpx~=0.28.1 \
    loguru~=0.7.3 \
    -i https://mirrors.aliyun.com/pypi/simple/
