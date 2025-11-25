#!/bin/bash

BUILD_IMAGE_NAME="openssh-server:latest"
INIT_GROUPS=$(yq -c .groups test-vars.yml)
INIT_USERS=$(yq -c .users test-vars.yml)
INIT_CREATE_DIRS=$(yq -c '.create_dirs' test-vars.yml)
INIT_SSHD_PORT=$(yq -c .sshd_config.Port test-vars.yml)
INIT_SSHD_CONFIG=$(yq -c .sshd_config test-vars.yml)

if [ "$DEBUG" = "1" ] || [ "$DEBUG" = "TRUE" ] || [ "$DEBUG" = "true" ]; then
    DEBUG_ON=1
    set -x
else
    DEBUG_ON=0
fi

cleanup() {
    echo "テストに使ったコンテナ削除します..."
	docker stop $CONTAINER_NAME || true
}
trap cleanup EXIT

set -e

CONTAINER_NAME=$(docker run  \
	--detach \
	--rm \
	-p 2222:$INIT_SSHD_PORT \
	-e DEBUG=$DEBUG \
	-e INIT_GROUPS="$INIT_GROUPS" \
	-e INIT_USERS="$INIT_USERS" \
	-e INIT_SSHD_CONFIG="$INIT_SSHD_CONFIG" \
	-e INIT_CREATE_DIRS="$INIT_CREATE_DIRS" \
	$BUILD_IMAGE_NAME)
echo CONTAINER_NAME: $CONTAINER_NAME

sleep 3

{
	echo "Generating test_known_hosts"
	ssh-keyscan -p 2222 localhost | tee ./test_known_hosts
}

{
	echo example1 should be able to login
	r=$(sshpass -p "password1" ssh -F test_ssh_config -o PreferredAuthentications=password example1@openssh-server-testing echo "example1 login successful")
	if [ "$r" != "example1 login successful" ]; then
	  echo "example1 login failed"
	  exit 1
	fi
}

{
	echo example2 should NOT be able to login
	set +e
	ssh -F ./test_ssh_config -o IdentityFile=./test_key_ed25519 -o IdentitiesOnly=yes example2@openssh-server-testing
	if [ $? -eq 0 ]; then
	  echo "example2 ssh login MUST fail but succeeded"
	  exit 1
	fi
}

{
	echo example2 should be able to copy file via scp
	scp -F ./test_ssh_config -o IdentityFile=./test_key_ed25519 -o IdentitiesOnly=yes \
		./README.md \
		example2@openssh-server-testing:/data
	if [ $? -ne 0 ]; then
	  echo "example2 scp MUST succeed but failed"
	  exit 1
	fi

	echo "Verifying copied file content"
	docker cp $CONTAINER_NAME:/chroot/example2/data/README.md ./tmp/README_copied.md
	diff ./README.md ./tmp/README_copied.md
	if [ $? -ne 0 ]; then
	  echo "Copied file content does not match"
	  exit 1
	fi
}

echo "###### All tests passed successfully. #######"