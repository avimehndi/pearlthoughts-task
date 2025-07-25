#!/bin/bash

    apt update -y
    apt install -y docker.io
    systemctl start docker
    systemctl enable docker

    docker network create strapi-net

    docker run -d --name postgres --network strapi-net \
      -e POSTGRES_DB=strapi \
      -e POSTGRES_USER=strapi \
      -e POSTGRES_PASSWORD=strapi \
      -v /srv/pgdata:/var/lib/postgresql/data \
      postgres:15

    docker pull avimehndi/strapi:latest

    docker run -d --name strapi --network strapi-net \
      -e DATABASE_CLIENT=postgres \
      -e DATABASE_HOST=postgres \
      -e DATABASE_PORT=5432 \
      -e DATABASE_NAME=strapi \
      -e DATABASE_USERNAME=strapi \
      -e DATABASE_PASSWORD=strapi \
      -e APP_KEYS=468cnhT7DiBFuGxUXVh8tA==,0ijw28sTuKb2Xi2luHX6zQ==,TfN3QRc00kFU3Qtg320QNg==,hHRI+D6KWZ0g5PER1WanWw== \
      -e API_TOKEN_SALT=PmzN60QIfFJBz4tGtWWrDg== \
      -e ADMIN_JWT_SECRET=YBeqRecVoyQg7PJGSLv1hg== \
      -p 1337:1337 \
      avimehndi/strapi:latest