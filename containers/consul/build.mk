rule_target := consul
rule_prerequisites :=
rule_recipes := $(call download_image_tar_from_filerepo,consul-v1.14.2-docker.tar.zst)