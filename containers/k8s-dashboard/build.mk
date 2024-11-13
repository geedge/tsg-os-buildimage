rule_target := k8s-dashboard
rule_prerequisites :=
define rule_recipes
	$(call download_image_tar_from_filerepo,k8s-dashboard-v2.7.0-docker.tar)
endef
