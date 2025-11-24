#!/bin/bash
BUILD_IMAGE_NAME=$1
TARGET=$2
TO_DIR=$2

CONTAINER_ID=$(docker create ${BUILD_IMAGE_NAME})
docker container cp --archive --follow-link $CONTAINER_ID:${TARGET} ./tmp/${filename}
docker container rm $CONTAINER_ID > /dev/null