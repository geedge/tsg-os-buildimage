rule_target := dynamic-hostport
rule_prerequisites :=
rule_recipes := $(call download_image_tar_from_url,dynamic-hostport.tar)