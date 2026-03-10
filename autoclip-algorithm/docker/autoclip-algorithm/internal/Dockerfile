# 使用NVIDIA官方的CUDA镜像作为基础镜像
FROM nvidia/cuda:12.8.1-devel-ubuntu24.04

LABEL authors="hhoa"

ENV DEBIAN_FRONTEND=noninteractive \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility


RUN sed -i 's@//.*archive.ubuntu.com@//mirrors.aliyun.com@g' /etc/apt/sources.list.d/ubuntu.sources && \
    sed -i 's@//.*security.ubuntu.com@//mirrors.aliyun.com@g' /etc/apt/sources.list.d/ubuntu.sources

RUN apt update && \
    apt-get install -y \
    software-properties-common \
    wget \
    curl \
    build-essential \
    ffmpeg \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y \
    python3.12\
    python3.12-dev \
    python3.12-venv \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/bin/python3.12 /usr/bin/python && \
    ln -sf /usr/bin/python3.12 /usr/bin/python3

WORKDIR /autoclip/algorithm/

RUN python -m venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH" \
    env=prod

# 安装PyTorch GPU版本 (根据CUDA版本选择合适的torch版本)
# RUN python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

RUN python -m pip install ultralytics~=8.3.130 -i https://mirrors.aliyun.com/pypi/simple/

COPY requirements.txt /autoclip/algorithm/

RUN python -m pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

ADD autoclip-algorithm.tar.gz /autoclip/algorithm/
