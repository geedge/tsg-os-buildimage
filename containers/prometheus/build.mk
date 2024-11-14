rule_target := prometheus
rule_prerequisites :=
rule_recipes := $(call download_image_tar_from_filerepo,prometheus-v25.8.2-docker.tar.zst)