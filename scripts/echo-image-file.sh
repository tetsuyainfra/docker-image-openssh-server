#!/bin/bash
BUILD_IMAGE_NAME=$1
TARGET_FILE=$2

filename=$(basename "$TARGET_FILE")

CONTAINER_ID=$(docker create ${BUILD_IMAGE_NAME})
# docker container cp $CONTAINER_ID:/usr/share/rocks/packages.list ./tmp/packages.list > /dev/null
docker container cp $CONTAINER_ID:${TARGET_FILE} ./tmp/${filename} > /dev/null
cat ./tmp/${filename}
docker container rm $CONTAINER_ID > /dev/null