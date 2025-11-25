include .env

# SRC_FILES := $(wildcard src/*)
SRC_FILES := $(shell find src -type f)

BUILD_TIMESTAMP_FILE := tmp/.build-timestamp
BUILD_IMAGE_NAME := openssh-server:latest

TEST_CONTAINER_NAME := ssh-server-testing

TEST_INIT_GROUPS := $(shell yq -c .groups test-vars.yml)
TEST_INIT_USERS := $(shell yq -c .users test-vars.yml)
TEST_INIT_SSHD_PORT := $(shell yq -c .sshd_config.Port test-vars.yml)
TEST_INIT_SSHD_CONFIG := $(shell yq -c .sshd_config test-vars.yml)
TEST_INIT_CREATE_DIRS := $(shell yq -c '.create_dirs' test-vars.yml)

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
	docker builder prune -f


build: $(BUILD_TIMESTAMP_FILE)
$(BUILD_TIMESTAMP_FILE): $(SRC_FILES)
	docker build \
		--build-arg HTTP_PROXY=$(HTTP_PROXY) \
		--build-arg HTTPS_PROXY=$(HTTPS_PROXY) \
		-t $(BUILD_IMAGE_NAME) \
		-f src/Dockerfile ./src
	touch $@


run: $(BUILD_TIMESTAMP_FILE)
	docker run --name $(TEST_CONTAINER_NAME) \
		--rm \
		-p 2222:$(TEST_INIT_SSHD_PORT) \
		-e DEBUG=$(DEBUG) \
		-e INIT_GROUPS='$(TEST_INIT_GROUPS)' \
		-e INIT_USERS='$(TEST_INIT_USERS)' \
		-e INIT_SSHD_CONFIG='$(TEST_INIT_SSHD_CONFIG)' \
		-e INIT_CREATE_DIRS='$(TEST_INIT_CREATE_DIRS)' \
		$(BUILD_IMAGE_NAME)

start: $(BUILD_TIMESTAMP_FILE)
	docker run --name $(TEST_CONTAINER_NAME) \
		-p 2222:$(TEST_INIT_SSHD_PORT) \
		-e DEBUG=$(DEBUG) \
		-e INIT_GROUPS='$(TEST_INIT_GROUPS)' \
		-e INIT_USERS='$(TEST_INIT_USERS)' \
		-e INIT_SSHD_CONFIG='$(TEST_INIT_SSHD_CONFIG)' \
		-e INIT_CREATE_DIRS='$(TEST_INIT_CREATE_DIRS)' \
		$(BUILD_IMAGE_NAME)

vars:
	@echo '$(TEST_INIT_GROUPS)'
	@echo '$(TEST_INIT_USERS)'
	@echo '$(TEST_INIT_SSHD_CONFIG)'
	@echo '$(TEST_INIT_CREATE_DIRS)'

# test: $(BUILD_TIMESTAMP_FILE)
# 	docker run --rm -d --name $(TEST_CONTAINER_NAME) -p 3142:3142 \
# 		-e TOP_MIRROR_DEBIAN='$(TOP_MIRROR_DEBIAN)' \
# 		-e TOP_MIRROR_UBUNTU='$(TOP_MIRROR_UBUNTU)' \
# 		-e USE_CRON=TRUE \
# 		-e CRON_SCHEDULE="* 4 * * *" \
# 		-e ALLOW_USER_PORTS="80 443" \
# 		-e ADD_REPOS='$(TEST_ADD_REPOS)' \
# 		acng:latest
# 	PROXY=localhost:3142 ./test.sh || { \
# 		echo "Tests failed." ; \
# 		docker stop $(TEST_CONTAINER_NAME) ; \
# 		exit 1; \
# 	};
# 	docker stop $(TEST_CONTAINER_NAME)


# shell: $(BUILD_TIMESTAMP_FILE)
# 	docker exec -it acng-testing /bin/bash


# just_run: $(BUILD_TIMESTAMP_FILE)
# 	docker run --rm --name acng-testing -p 3142:3142 acng:latest


# conf_acng: $(BUILD_TIMESTAMP_FILE)
# # Copy default config files from the image to local directory ./tmp
# # but /etc/apt-cacher-ng include link files
# 	CONTAINER_ID=$$(docker create acng:latest) ; \
# 	docker container cp -aL $$CONTAINER_ID:/etc/apt-cacher-ng ./tmp ; \
# 	docker container rm $$CONTAINER_ID

cp_ssh_config: $(BUILD_TIMESTAMP_FILE)
	@./scripts/cp-image-file.sh $(BUILD_IMAGE_NAME) /etc/ssh ./tmp

cp_rocks: $(BUILD_TIMESTAMP_FILE)
	@./scripts/cp-image-file.sh $(BUILD_IMAGE_NAME) /usr/share/rocks/packages.list ./tmp

