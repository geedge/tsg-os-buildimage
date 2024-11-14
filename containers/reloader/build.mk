rule_target := reloader
rule_prerequisites :=
rule_recipes := $(call download_image_tar_from_filerepo,reloader-v1.0.22-docker.tar.zst)