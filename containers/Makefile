export YUM_REPO_FILE
export IMAGE_TAG

BUILD_DIR := build

IMAGE_NAMES := $(shell find . -maxdepth 1 -type d ! -name "build" ! -name "." | sed 's|^\./||')
IMAGE_REGISTRY := registry.gdnt-cloud.website/tsg/os
IMAGE_TAR_DIR := $(BUILD_DIR)/images


ENV_FILES := $(BUILD_DIR)/IMAGE_TAG_$(IMAGE_TAG:/=_).env

ARCH := $(shell uname -m)

ifeq ($(ARCH),x86_64)
IMAGE_ARCH := amd64
else ifeq ($(ARCH),aarch64)
IMAGE_ARCH := arm64
else
IMAGE_ARCH := unknown
endif

define write_env_files
$(1):
	mkdir -p $(BUILD_DIR); echo $(1) > $(1)
endef

DOCKERFILE_MACROS := dockerfile-macros.j2

BUILD_DONE_FILE := build.done

define build_rule
$(1): $(BUILD_DIR)/$(1)/$(BUILD_DONE_FILE)

$(BUILD_DIR)/$(1)/$(BUILD_DONE_FILE): $(shell find $(1) -type f) $(2)
	@mkdir -p $(BUILD_DIR)/$(1)
	@mkdir -p $(IMAGE_TAR_DIR)
	$(3)
	@echo done > $(BUILD_DIR)/$(1)/$(BUILD_DONE_FILE)
endef

define build_image_from_dockerfile
	/usr/local/bin/j2 -f yaml $(1)/Dockerfile.j2 $(1)/manifest.yaml -o $(BUILD_DIR)/$(1)/Dockerfile
	buildah build \
	--volume /etc/hosts:/etc/hosts:ro \
	--volume $(YUM_REPO_FILE):/etc/yum.conf:ro \
	--volume $(YUM_REPO_FILE):/etc/dnf/dnf.conf:ro \
	-f $(BUILD_DIR)/$(1)/Dockerfile \
	--build-arg BASE_IMAGE=$(2) \
	-t $(3) \
	$(1)
endef

define download_image_tar_from_url
	curl -f -u "${PULP_REPO_USERNAME}:${PULP_REPO_PASSWORD}" \
		-o $(IMAGE_TAR_DIR)/$(1) \
		https://repo.geedge.net/filerepo/install/release/tsg-container-images/$(1)
endef

.PHONY: all clean $(IMAGE_NAMES)

all: $(IMAGE_NAMES)

$(foreach name,$(IMAGE_NAMES),\
	$(eval include $(name)/build.mk);\
	$(eval $(call build_rule,$(rule_target),$(rule_prerequisites),$(rule_recipes))))

$(foreach file,$(ENV_FILES),$(eval $(call write_env_files,$(file))))

clean:
	rm -rf $(BUILD_DIR)