#!/bin/bash


echo -n  > ./test_known_hosts
ssh  -F ./test_ssh_config -o PreferredAuthentications=password example1@openssh-server-testing


# ssh -F ./test_ssh_config -o IdentityFile=./test_key_ed25519 -o IdentitiesOnly=yes example2@openssh-server-testing

	docker run --name $(TEST_CONTAINER_NAME) \
		--rm \
		-p 2222:$(TEST_INIT_SSHD_PORT) \
		-e DEBUG=$(DEBUG) \
		-e INIT_GROUPS='$(TEST_INIT_GROUPS)' \
		-e INIT_USERS='$(TEST_INIT_USERS)' \
		-e INIT_SSHD_CONFIG='$(TEST_INIT_SSHD_CONFIG)' \
		-e INIT_CREATE_DIRS='$(TEST_INIT_CREATE_DIRS)' \
		$(BUILD_IMAGE_NAME)