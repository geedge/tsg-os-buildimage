rule_target := tsg-cm
rule_prerequisites :=
rule_recipes := $(call copy_helmchart_package,$(rule_target))