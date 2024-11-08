rule_target := consul
rule_prerequisites :=
rule_recipes := $(call download_image_tar_from_url,consul.tar)