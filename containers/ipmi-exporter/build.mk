rule_target := ipmi-exporter
rule_prerequisites :=
define rule_recipes
	$(call download_image_tar_from_url,ipmi-exporter.tar)
endef
