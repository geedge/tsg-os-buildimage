rule_target := dynamic-hostport
rule_prerequisites :=

define rule_recipes
	$(call copy_manifest,$(rule_target))
endef
