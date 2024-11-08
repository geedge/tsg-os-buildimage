rule_target := helm-controller
rule_prerequisites :=
rule_recipes := curl -f -u "${PULP_REPO_USERNAME}:${PULP_REPO_PASSWORD}" -o $(IMAGE_TAR_DIR)/k3s-helm-controller-amd64.tar \
					https://repo.geedge.net/filerepo/install/release/os-build-files/k3s/v1.29.2/k3s-helm-controller-amd64.tar