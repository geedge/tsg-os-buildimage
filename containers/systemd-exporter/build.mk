rule_target := systemd-exporter
rule_prerequisites :=
define rule_recipes
	$(call download_image_tar_from_filerepo,exporter-merger-v0.2.0-docker.tar)
endef
