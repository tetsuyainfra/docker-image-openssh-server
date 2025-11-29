#!/bin/bash

IMAGE_NAME="${IMAGE_NAME:-tetsuyainfra/openssh-server:trixie-latest}"
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

RETURN_CODE=1
cleanup() {
	RET=$?
	[ $DEBUG_ON == 1 ] && echo "catch: EXIT signal. return code=$RET"
    echo "テストに使ったコンテナを削除します..."
	docker stop $CONTAINER_NAME || true

	exit $RET
}
# SIGINT（Ctrl+C）のハンドラ
handle_sigint() {
    echo "Caught SIGINT (Ctrl+C)"
    exit 1
}

trap cleanup EXIT
trap handle_sigint SIGINT


set -e

CONTAINER_NAME=$(docker run  \
	--detach \
	--rm \
	-p 2222:$INIT_SSHD_PORT \
	-e DEBUG=$DEBUG_ON \
	-e INIT_GROUPS="$INIT_GROUPS" \
	-e INIT_USERS="$INIT_USERS" \
	-e INIT_SSHD_CONFIG="$INIT_SSHD_CONFIG" \
	-e INIT_CREATE_DIRS="$INIT_CREATE_DIRS" \
	$IMAGE_NAME)
echo IMAGE_NAME: $IMAGE_NAME
echo CONTAINER_NAME: $CONTAINER_NAME

sleep 3

{
	echo TEST Check init_useradd, init_sshd_config created
	docker exec $CONTAINER_NAME test -e /config
	docker exec $CONTAINER_NAME test -e /config/init_useradd
	docker exec $CONTAINER_NAME test -e /config/init_sshd_config
}
{
	echo Ensure groups has been created
	docker exec $CONTAINER_NAME cat /etc/group
	docker exec $CONTAINER_NAME cat /etc/group | grep 'example1:x:1000:' > /dev/null
	docker exec $CONTAINER_NAME cat /etc/group | grep 'sftp:x:2000:' > /dev/null
}
{
	echo Ensure users has been created
	# !以外ってことは2以上なのでパスワード設定済み
	docker exec $CONTAINER_NAME cat /etc/shadow | grep 'example1:[^:]\{2,\}:' > /dev/null
	docker exec $CONTAINER_NAME cat /etc/shadow | grep 'example2:\!:' > /dev/null
}

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


echo ""
echo "###### All tests passed successfully. #######"
echo ""