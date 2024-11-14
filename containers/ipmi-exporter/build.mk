rule_target := ipmi-exporter
rule_prerequisites :=
define rule_recipes
	$(call download_image_tar_from_filerepo,ipmi-exporter-v1.2.0-docker.tar.zst)
endef
