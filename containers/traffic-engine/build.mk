requisites_images_name := firewall proxy proxy-certstore sce sce-bfdd shaping
rule_target := traffic-engine
rule_prerequisites := $(foreach name,$(requisites_images_name),$(BUILD_DIR)/$(name)/$(BUILD_DONE_FILE))
rule_recipes := rm -rf $(IMAGE_TAR_DIR)/$(rule_target)-$(IMAGE_TAG)-$(IMAGE_ARCH)-docker.tar;\
				podman save \
				-o $(IMAGE_TAR_DIR)/$(rule_target)-$(IMAGE_TAG)-$(IMAGE_ARCH)-docker.tar \
				-m $(foreach name,$(requisites_images_name),$(IMAGE_REGISTRY)/$(name):$(IMAGE_TAG))