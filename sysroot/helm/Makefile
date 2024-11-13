export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL

.PHONY: x86_64_COTS AArch64_COTS install

x86_64_COTS: preinstall_x86_64 install

AArch64_COTS: preinstall_aarch64 install

preinstall_x86_64:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		mkdir -p /tmp/helm; \
		tar --strip-components=1 -zxvf $(TMP_FILES_DIR)/helm-v3.13.3-linux-amd64.tar.gz -C /tmp/helm/; \
	'

preinstall_aarch64:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		mkdir -p /tmp/helm; \
		tar --strip-components=1 -zxvf $(TMP_FILES_DIR)/helm-v3.13.3-linux-arm64.tar.gz -C /tmp/helm/; \
	'

install:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		install -D -m 0755 /tmp/helm/helm /usr/bin/helm; \
		rm -rf /tmp/helm; \
		helm completion bash > /etc/bash_completion.d/helm; \
	'