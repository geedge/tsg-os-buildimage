export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL

.PHONY: all chroot-commands

all: chroot-commands

chroot-commands:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		mkdir -p /tmp/helm; \
		tar -zxvf $(TMP_FILES_DIR)/helm-linux-amd64.tar.gz -C /tmp/helm/; \
		install -D -m 0755 /tmp/helm/linux-amd64/helm /usr/bin/helm; \
		rm -rf /tmp/helm; \
		helm completion bash > /etc/bash_completion.d/helm; \
	'