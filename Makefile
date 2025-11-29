include .env

# SRC_FILES := $(wildcard src/*)
SRC_FILES := $(shell find src -type f)

BUILD_TIMESTAMP_FILE := tmp/.build-timestamp
BUILD_IMAGE_NAME := tetsuyainfra/openssh-server:trixie-latest

TEST_CONTAINER_NAME := ssh-server-testing

# yq command options
# --output json | -o json : output json format
# --indent 0 | -I 0       : no pretty print)
TEST_INIT_GROUPS := $(shell yq -I 0 -o json .groups test-vars.yml)
TEST_INIT_USERS := $(shell yq -I 0 -o json .users test-vars.yml)
TEST_INIT_SSHD_PORT := $(shell yq -I 0 -o json .sshd_config.Port test-vars.yml)
TEST_INIT_SSHD_CONFIG := $(shell yq -I 0 -o json .sshd_config test-vars.yml)
TEST_INIT_CREATE_DIRS := $(shell yq -I 0 -o json '.create_dirs' test-vars.yml)

.PHONY: build
ALL: build

clean:
	docker stop  $(TEST_CONTAINER_NAME) || true
	docker rm  $(TEST_CONTAINER_NAME) || true
	docker rmi $(BUILD_IMAGE_NAME) || true
	find ./tmp \
		-maxdepth 1 \
		! -path './tmp' \
		! -name '.' \
		! -name .gitignore \
		-exec rm -r {} +
# 		-exec echo {} +

clean_cache: clean
	docker image prune -f
	docker builder prune -f


build: $(BUILD_TIMESTAMP_FILE)
$(BUILD_TIMESTAMP_FILE): $(SRC_FILES)
	docker buildx bake --progress=plain
	touch $@


run: $(BUILD_TIMESTAMP_FILE)
	docker run --name $(TEST_CONTAINER_NAME) \
		--rm \
		-p 2222:$(TEST_INIT_SSHD_PORT) \
		-e DEBUG=$(DEBUG) \
		-e INIT_GROUPS='$(TEST_INIT_GROUPS)' \
		-e INIT_USERS='$(TEST_INIT_USERS)' \
		-e INIT_CREATE_DIRS='$(TEST_INIT_CREATE_DIRS)' \
		-e INIT_SSHD_CONFIG='$(TEST_INIT_SSHD_CONFIG)' \
		$(BUILD_IMAGE_NAME)

run2: $(BUILD_TIMESTAMP_FILE)
	docker run --name $(TEST_CONTAINER_NAME) \
		--rm \
		-v ./test-vars.yml:/test-vars.yml:ro \
		-p 2222:$(TEST_INIT_SSHD_PORT) \
		-e DEBUG=$(DEBUG) \
		-e INIT_CONFIG='/test-vars.yml' \
		$(BUILD_IMAGE_NAME)

vars:
	@echo '$(TEST_INIT_GROUPS)'
	@echo '$(TEST_INIT_USERS)'
	@echo '$(TEST_INIT_SSHD_CONFIG)'
	@echo '$(TEST_INIT_CREATE_DIRS)'

test: $(BUILD_TIMESTAMP_FILE)
	IMAGE_NAME=$(BUILD_IMAGE_NAME) ./test.sh

cp_ssh_config: $(BUILD_TIMESTAMP_FILE)
	@./scripts/cp-image-file.sh $(BUILD_IMAGE_NAME) /etc/ssh ./tmp

cp_rocks: $(BUILD_TIMESTAMP_FILE)
	@./scripts/cp-image-file.sh $(BUILD_IMAGE_NAME) /usr/share/rocks/packages.list ./tmp

