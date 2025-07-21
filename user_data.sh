#!/bin/bash
apt update -y
apt install -y docker.io
systemctl start docker
systemctl enable docker

docker pull ${docker_image}
docker run -d -p 80:1337 ${docker_image}
