rule_target := helm-controller
rule_prerequisites :=

define rule_recipes
	$(call copy_manifest,$(rule_target))
endef
