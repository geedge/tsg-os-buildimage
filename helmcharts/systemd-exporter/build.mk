rule_target := systemd-exporter
rule_prerequisites :=
define rule_recipes
	$(call build_helmchart_package,$(rule_target),0.1.0,0.1.0)
	$(call copy_manifest,$(rule_target))
endef