export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL
export KERNEL_RELEASE

.PHONY: x86_64_COTS AArch64_COTS install-x86_64 install-aarch64

x86_64_COTS: install-x86_64
AArch64_COTS: install-aarch64

install-x86_64:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		mkdir -p /tmp/mft/unarchived; \
		sed -i -e 's/KERNEL_RELEASE/$(KERNEL_RELEASE)/' $(TMP_FILES_DIR)/uname; \
		bash $(TMP_FILES_DIR)/uname_hook.sh --hook; \
		dnf -y install mlnx-ofed-kernel-only-all-5.17.15-1.el8.x86_64.noarch; \
		tar -zxvf $(TMP_FILES_DIR)/mft-4.22.1-11-x86_64-rpm.tgz -C /tmp/mft/unarchived/; \
		/tmp/mft/unarchived/mft-4.22.1-11-x86_64-rpm/install.sh; \
		dnf -y install $(TMP_FILES_DIR)/mlnx-fw-updater-5.8-2.0.3.0.x86_64.rpm; \
		sed -i "/^RUN_FW_UPDATER_ONBOOT/c\RUN_FW_UPDATER_ONBOOT=no"  /etc/infiniband/openib.conf; \
		bash $(TMP_FILES_DIR)/uname_hook.sh --recover; \
		install -D -m 0644 $(TMP_FILES_DIR)/90-nvidia-cx6-enable-dropless-rq.rules -t /usr/lib/udev/rules.d/; \
		install -D -m 0755 $(TMP_FILES_DIR)/enable_dropless_rq.sh -t /usr/local/sbin/; \
	'

install-aarch64:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		cp $(TMP_FILES_DIR)/doca-aarch64.repo /etc/yum.repos.d/doca.repo; \
		sed -i -e 's/KERNEL_RELEASE/$(KERNEL_RELEASE)/' $(TMP_FILES_DIR)/uname; \
		bash $(TMP_FILES_DIR)/uname_hook.sh --hook; \
		dnf -y install doca-ofed; \
		bash $(TMP_FILES_DIR)/uname_hook.sh --recover; \
	'