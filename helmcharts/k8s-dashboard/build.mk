rule_target := k8s-dashboard
rule_prerequisites :=

define rule_recipes
	$(call copy_manifest,$(rule_target))
endef
