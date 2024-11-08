rule_target := multus-cni
rule_prerequisites :=
rule_recipes := $(call download_image_tar_from_url,multus-cni.tar)