rule_target := reloader
rule_prerequisites :=
rule_recipes := $(call download_image_tar_from_url,reloader.tar)