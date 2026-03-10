#!/usr/bin/env bash
docker_registry=115.159.107.142:5000
branch=$(git symbolic-ref --short HEAD)
repository_root=$(git rev-parse --show-toplevel)
image_name='autoclip-algorithm'

docker_file_dir=$repository_root/docker/autoclip-algorithm/internal

cd "$repository_root" || exit
git archive "$branch" --format=tar.gz --output="${docker_file_dir}"/"${image_name}".tar.gz

cd "${docker_file_dir}" || exit
tar -xzf "${image_name}".tar.gz -C ./ requirements.txt

docker build --progress=plain . -t "${image_name}":latest || exit

docker tag "${image_name}":latest "${image_name}":1.0

docker tag "${image_name}":latest ${docker_registry}/"${image_name}":1.0
docker tag "${image_name}":latest ${docker_registry}/"${image_name}":latest

docker push ${docker_registry}/"${image_name}":1.0
docker push ${docker_registry}/"${image_name}":latest

rm -rf "${image_name}".tar.gz requirements.txt
