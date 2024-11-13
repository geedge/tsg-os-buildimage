rule_target := cm-cache
rule_prerequisites :=
rule_recipes := $(call download_image_tar_from_filerepo,redis-v7.2.4-docker.tar)