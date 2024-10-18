rule_target := nic-uio-binder
rule_prerequisites :=
rule_recipes := $(call render_manifest_from_env,$(rule_target),nic-uio-binder.yaml)