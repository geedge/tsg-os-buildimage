rule_target := sce
rule_prerequisites := $(DEP_ENV_FILES) $(YUM_REPO_FILE) $(DOCKERFILE_MACROS) $(BUILD_DIR)/base/$(BUILD_DONE_FILE)
rule_recipes := $(call build_image_from_dockerfile,$(rule_target),$(IMAGE_REGISTRY)/base:$(IMAGE_TAG),$(IMAGE_REGISTRY)/$(rule_target):$(IMAGE_TAG))