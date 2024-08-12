rule_target := base
rule_prerequisites := $(DEP_ENV_FILES) $(YUM_REPO_FILE) $(DOCKERFILE_MACROS)
rule_recipes := $(call build_image_from_dockerfile,$(rule_target),rockylinux:8,$(IMAGE_REGISTRY)/$(rule_target):$(IMAGE_TAG))