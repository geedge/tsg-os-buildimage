rule_target := trex
rule_prerequisites :=
rule_recipes := $(call build_helmchart_package,$(rule_target),$(VERSION),$(APP_VERSION))