rule_target := prometheus
rule_prerequisites :=
rule_recipes := $(call download_image_tar_from_url,prometheus-v25.8.2.tar)