rule_target := helm-controller
rule_prerequisites :=
rule_recipes := $(call download_image_tar_from_filerepo,helm-controller-v0.15.8.docker.tar.zst)