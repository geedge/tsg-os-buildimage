rule_target := multus-cni
rule_prerequisites :=
rule_recipes := $(call copy_manifest,$(rule_target))