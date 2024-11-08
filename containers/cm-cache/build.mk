rule_target := cm-cache
rule_prerequisites :=
rule_recipes := $(call download_image_tar_from_url,redis-7.2.4.tar)