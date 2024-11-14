export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL
export MACHINE_ID

ifeq ($(MACHINE_ID),x86_64_COTS)
k3s_bin := k3s
k3s_airgap := k3s-airgap-images-amd64.tar.zst
else ifeq ($(MACHINE_ID),AArch64_COTS)
k3s_bin := k3s-arm64
k3s_airgap := k3s-airgap-images-arm64.tar.zst
else
k3s_bin := unknown
k3s_airgap := unknown
endif

.PHONY: x86_64_COTS AArch64_COTS install install_cni_x86_64 install_cni_aarch64

x86_64_COTS: install install_cni_x86_64

AArch64_COTS: install install_cni_aarch64

install:
	echo "machine repo.geedge.net" > $(CHROOT_DIR)/$(TMP_FILES_DIR)/netrc.conf
	echo "login ${PULP_REPO_USERNAME}" >> $(CHROOT_DIR)/$(TMP_FILES_DIR)/netrc.conf
	echo "password ${PULP_REPO_PASSWORD}" >> $(CHROOT_DIR)/$(TMP_FILES_DIR)/netrc.conf
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		sed -ie "s/SELINUX=.*/SELINUX=disabled/g" /etc/selinux/config; \
		curl --netrc-file $(TMP_FILES_DIR)/netrc.conf \
			-o /usr/bin/k3s \
			https://repo.geedge.net/filerepo/install/release/os-build-files/k3s/v1.29.2/$(k3s_bin); \
		chmod 0755 /usr/bin/k3s; \
		mkdir -p /var/lib/rancher/k3s/agent/images; \
		curl --netrc-file $(TMP_FILES_DIR)/netrc.conf \
			-o /var/lib/rancher/k3s/agent/images/$(k3s_airgap) \
			https://repo.geedge.net/filerepo/install/release/os-build-files/k3s/v1.29.2/$(k3s_airgap); \
		curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | \
			INSTALL_K3S_MIRROR=cn INSTALL_K3S_SKIP_DOWNLOAD=true INSTALL_K3S_SKIP_ENABLE=true \
			INSTALL_K3S_BIN_DIR=/usr/bin INSTALL_K3S_SYSTEMD_DIR=/usr/lib/systemd/system \
			sh -s - --flannel-backend=none --node-name=localhost --disable-helm-controller --disable=traefik; \
		systemctl enable k3s; \
		kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null; \
		install -D -m 0644 $(TMP_FILES_DIR)/kubectl.fish -t /usr/share/fish/completions/; \
		install -D -m 0644 $(TMP_FILES_DIR)/k3s.service.env -t /usr/lib/systemd/system/; \
		install -D -m 0644 $(TMP_FILES_DIR)/10-bridge.conf -t /etc/cni/net.d/; \
		install -D -m 0644 $(TMP_FILES_DIR)/config.yaml -t /etc/rancher/k3s/; \
		install -D -m 0644 $(TMP_FILES_DIR)/service_set_RuntimeMaxSec.conf -t /usr/lib/systemd/system/k3s.service.d/; \
		install -D -m 0755 $(TMP_FILES_DIR)/k3s-reset.sh -t /usr/bin/; \
		install -D -m 0644 $(TMP_FILES_DIR)/kubeconfig.sh -t /etc/profile.d/; \
		install -D -m 0644 $(TMP_FILES_DIR)/00-kubconfig -t /etc/sudoers.d/; \
	'

install_cni_x86_64:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		mkdir -p /opt/cni/bin; tar -zxvf $(TMP_FILES_DIR)/cni-plugins-linux-amd64-v1.4.0.tgz -C /opt/cni/bin; \
	'

install_cni_aarch64:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		mkdir -p /opt/cni/bin; tar -zxvf $(TMP_FILES_DIR)/cni-plugins-linux-arm64-v1.4.0.tgz -C /opt/cni/bin; \
	'