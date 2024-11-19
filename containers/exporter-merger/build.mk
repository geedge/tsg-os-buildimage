rule_target := exporter-merger
rule_prerequisites :=
define rule_recipes
	$(call download_image_tar_from_filerepo,exporter-merger-latest-docker.tar.zst)
endef
