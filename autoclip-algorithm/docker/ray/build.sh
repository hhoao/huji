#!/usr/bin/env bash
export HTTP_PROXY=http://127.0.0.1:7897
export HTTPS_PROXY=http://127.0.0.1:7897
export NO_PROXY=localhost,127.0.0.1

docker_registry=115.159.107.142:5000

repository_root=$(git rev-parse --show-toplevel)
image_name='autoclip-ray'
docker_file_dir=$repository_root/docker/ray/internal

cd "${docker_file_dir}" || exit

docker build --progress=plain . -t "${image_name}":latest || exit

docker tag "${image_name}":latest "${image_name}":1.0

docker tag "${image_name}":latest ${docker_registry}/"${image_name}":1.0
docker tag "${image_name}":latest ${docker_registry}/"${image_name}":latest

docker push ${docker_registry}/"${image_name}":1.0
docker push ${docker_registry}/"${image_name}":latest
