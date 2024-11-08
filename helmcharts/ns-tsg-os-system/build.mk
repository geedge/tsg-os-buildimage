rule_target := ns-tsg-os-system
rule_prerequisites :=
rule_recipes := $(call copy_manifest,$(rule_target))