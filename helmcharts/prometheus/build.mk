rule_target := prometheus
rule_prerequisites :=

define rule_recipes
	$(call copy_helmchart_package,$(rule_target))
	$(call copy_manifest,$(rule_target))
endef
