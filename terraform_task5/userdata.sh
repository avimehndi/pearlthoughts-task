#!/bin/bash

exec > /var/log/user-data.log 2>&1

echo ">>> Updating packages"
sudo apt-get update -y

echo ">>> Installing Docker"
sudo apt-get install -y docker.io

echo ">>> Starting Docker service"
sudo systemctl start docker
sudo systemctl enable docker

echo ">>> Pulling Strapi Docker image"
sudo docker pull avimehndi/strapi:${docker_tag}

echo ">>> Removing old Strapi container if exists"
sudo docker rm -f strapi || true

echo ">>> Generating secrets for Strapi"
APP_KEYS="$(openssl rand -base64 32),$(openssl rand -base64 32)"
API_TOKEN_SALT="$(openssl rand -base64 16)"
ADMIN_JWT_SECRET="$(openssl rand -base64 32)"
JWT_SECRET="$(openssl rand -base64 32)"

echo ">>> Running Strapi container with secrets"
sudo docker run -d \
  --name strapi \
  -p 1337:1337 \
  --restart unless-stopped \
  -e APP_KEYS="$APP_KEYS" \
  -e API_TOKEN_SALT="$API_TOKEN_SALT" \
  -e ADMIN_JWT_SECRET="$ADMIN_JWT_SECRET" \
  -e JWT_SECRET="$JWT_SECRET" \
  avimehndi/strapi:${docker_tag}

echo ">>> Done setting up Strapi"

