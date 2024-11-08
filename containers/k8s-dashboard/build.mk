rule_target := k8s-dashboard
rule_prerequisites :=
define rule_recipes
	$(call download_image_tar_from_url,k8s-dashboard.tar)
	$(call download_image_tar_from_url,k8s-metrics-scraper.tar)
endef
