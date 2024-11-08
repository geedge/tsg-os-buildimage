rule_target := systemd-exporter
rule_prerequisites :=
define rule_recipes
	$(call download_image_tar_from_url,exporter-merger.tar)
endef
