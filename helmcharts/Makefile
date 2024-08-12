export VERSION
export APP_VERSION

HELMCHART_NAMES := $(shell find . -maxdepth 1 -type d ! -name "build" ! -name "." | sed 's|^\./||')

BUILD_DIR := build
HELMCHART_TAR_DIR := $(BUILD_DIR)/helmcharts
MANIFEST_DIR := $(BUILD_DIR)/manifests
BUILD_DONE_FILE := build.done

define build_rule
$(1): $(BUILD_DIR)/$(1)/$(BUILD_DONE_FILE)

$(BUILD_DIR)/$(1)/$(BUILD_DONE_FILE): $(shell find $(1) -type f) $(2)
	@mkdir -p $(BUILD_DIR)/$(1)
	$(3)
	@echo done > $(BUILD_DIR)/$(1)/$(BUILD_DONE_FILE)
endef

define build_helmchart_package
	@mkdir -p $(HELMCHART_TAR_DIR)
	/usr/local/bin/helm package --app-version $(3) --version $(2) -d $(HELMCHART_TAR_DIR) $(1)/helm
endef

define copy_helmchart_package
	@mkdir -p $(HELMCHART_TAR_DIR)
	cp $(1)/files/*.tgz $(HELMCHART_TAR_DIR)
endef

define copy_manifest
	@mkdir -p $(MANIFEST_DIR)
	cp $(1)/files/*.yaml $(MANIFEST_DIR)
endef

.PHONY: all clean $(HELMCHART_NAMES)

all: $(HELMCHART_NAMES)

$(foreach name,$(HELMCHART_NAMES),\
	$(eval include $(name)/build.mk);\
	$(eval $(call build_rule,$(rule_target),$(rule_prerequisites),$(rule_recipes)))))

clean:
	rm -rf $(BUILD_DIR)