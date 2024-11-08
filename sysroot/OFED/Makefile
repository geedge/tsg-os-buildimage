export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL

#KERNEL_RELEASE := $(shell chroot $(CHROOT_DIR) uname -r)
KERNEL_RELEASE := 5.17.15-1.el8.x86_64

.PHONY: all chroot-commands

all: chroot-commands

chroot-commands:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		mkdir -p /tmp/mft/unarchived; \
		install -D -m 0755 /usr/bin/uname /usr/bin/uname-backup; \
		install -D -m 0755 $(TMP_FILES_DIR)/uname /usr/bin/uname; \
		sed -i -e 's/KERNEL_RELEASE/$(KERNEL_RELEASE)/' /usr/bin/uname; \
		dnf -y install mlnx-ofed-kernel-only-all-5.17.15-1.el8.x86_64.noarch; \
		tar -zxvf $(TMP_FILES_DIR)/mft-4.22.1-11-x86_64-rpm.tgz -C /tmp/mft/unarchived/; \
		/tmp/mft/unarchived/mft-4.22.1-11-x86_64-rpm/install.sh; \
		dnf -y install $(TMP_FILES_DIR)/mlnx-fw-updater-5.8-2.0.3.0.x86_64.rpm; \
		sed -i "/^RUN_FW_UPDATER_ONBOOT/c\RUN_FW_UPDATER_ONBOOT=no"  /etc/infiniband/openib.conf; \
		install -D -m 0755 /usr/bin/uname-backup /usr/bin/uname; \
		install -D -m 0644 $(TMP_FILES_DIR)/90-nvidia-cx6-enable-dropless-rq.rules -t /usr/lib/udev/rules.d/; \
		install -D -m 0755 $(TMP_FILES_DIR)/enable_dropless_rq.sh -t /usr/local/sbin/; \
	'