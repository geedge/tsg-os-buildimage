rule_target := multus-cni
rule_prerequisites :=
rule_recipes := $(call download_image_tar_from_filerepo,multus-cni-v3.9.1-docker.tar)