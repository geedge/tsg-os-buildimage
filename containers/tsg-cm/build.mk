tsg_cm_image_registry := ci1.bj.geedge.net
tsg_cm_images := $(tsg_cm_image_registry)/tsg/cm/tsg-cm:api_v24.09_2024090501 \
				$(tsg_cm_image_registry)/common/mariadb:10.11.8 \
				$(tsg_cm_image_registry)/tsg/cm/cm-verify:tsg_v24.09_20240906

rule_target := tsg-cm
rule_prerequisites :=

define rule_recipes
	[ -z "${TSG_CM_IMAGE_REGISTRY_AUTH_USERNAME}" ] && echo "username not set." && exit 1 || true
	[ -z "${TSG_CM_IMAGE_REGISTRY_AUTH_PASSWORD}" ] && echo "password not set." && exit 1 || true

	buildah login \
	-u ${TSG_CM_IMAGE_REGISTRY_AUTH_USERNAME} \
	-p ${TSG_CM_IMAGE_REGISTRY_AUTH_PASSWORD} $(tsg_cm_image_registry); \
	for image in $(tsg_cm_images); do \
		buildah pull $$$$image || exit 1; \
	done

	mkdir -p $(IMAGE_TAR_DIR); \
	podman save -o $(IMAGE_TAR_DIR)/$(rule_target)-docker.tar -m $(tsg_cm_images)
endef