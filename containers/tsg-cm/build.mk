tsg_cm_image_registry := ci1.bj.geedge.net
tsg_cm_images := $(tsg_cm_image_registry)/tsg/cm/tsg-cm:api_v24.09_2024090501 \
				$(tsg_cm_image_registry)/common/mariadb:10.11.8 \
				$(tsg_cm_image_registry)/tsg/cm/cm-verify:tsg_v24.09_20240906

rule_target := tsg-cm
rule_prerequisites :=
rule_recipes :=