export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL

.PHONY: x86_64_COTS AArch64_COTS preinstall_x86_64 preinstall_aarch64 install

x86_64_COTS: preinstall_x86_64 install

AArch64_COTS: preinstall_aarch64 install

preinstall_x86_64:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL)  '\
		mkdir -p $(TMP_FILES_DIR)/unarchive; \
		tar --strip-components=1 -zxvf $(TMP_FILES_DIR)/systemd_exporter-0.6.0.linux-amd64.tar.gz -C $(TMP_FILES_DIR)/unarchive; \
	'

preinstall_aarch64:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL)  '\
		mkdir -p $(TMP_FILES_DIR)/unarchive; \
		tar --strip-components=1 -zxvf $(TMP_FILES_DIR)/systemd_exporter-0.6.0.linux-arm64.tar.gz -C $(TMP_FILES_DIR)/unarchive; \
	'

install:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		dnf -y install freeipmi --nogpgcheck; \
		install -D -m 0755 $(TMP_FILES_DIR)/unarchive/systemd_exporter -t /opt/tsg/exporter/; \
		install -D -m 0644 $(TMP_FILES_DIR)/exporter-systemd.service -t /usr/lib/systemd/system/; \
		systemctl enable exporter-systemd; \
	'