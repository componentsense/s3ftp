#!/bin/sh

docker rm s3ftp
docker build --target base -t s3ftp . && docker run --privileged --name s3ftp -p 21:21 --env-file ./.env s3ftp