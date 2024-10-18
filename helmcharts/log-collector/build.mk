rule_target := log-collector
rule_prerequisites :=
rule_recipes := $(call render_manifest_from_env,$(rule_target),log-collector.yaml)