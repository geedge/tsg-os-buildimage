requisites_images_name := firewall proxy proxy-certstore sce sce-bfdd shaping \
                          packet-io-engine inject-adapter trex nic-uio-binder \
                          log-collector dp-trace-telemetry
rule_target := tsg-os
rule_prerequisites := $(foreach name,$(requisites_images_name),$(BUILD_DIR)/$(name)/$(BUILD_DONE_FILE))
rule_recipes := rm -rf $(IMAGE_TAR_DIR)/$(rule_target)-$(IMAGE_TAG)-$(IMAGE_ARCH)-docker.tar;\
				podman save \
				-o $(IMAGE_TAR_DIR)/$(rule_target)-$(IMAGE_TAG)-$(IMAGE_ARCH)-docker.tar \
				-m $(foreach name,$(requisites_images_name),$(IMAGE_REGISTRY)/$(name):$(IMAGE_TAG))