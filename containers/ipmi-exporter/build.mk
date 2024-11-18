rule_target := ipmi-exporter
rule_prerequisites :=
define rule_recipes
	$(call download_image_tar_from_filerepo,prometheus-ipmi-exporter-v1.9.0-docker.tar.zst)
endef
