export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL

.PHONY: x86_64_COTS AArch64_COTS install

x86_64_COTS: install

AArch64_COTS: install

install:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		dnf -y install $(TMP_FILES_DIR)/aksusbd-8.31-1.x86_64.rpm --nogpgcheck; \
		systemctl disable aksusbd; \
		dnf -y install hasp-tools-1.0.12.66db85d --nogpgcheck; \
		install -D -m 0644 $(TMP_FILES_DIR)/service_override_env.conf -t /usr/lib/systemd/system/hasp_monitor.service.d/; \
		install -D -m 0644 $(TMP_FILES_DIR)/hasp_25743.ini -t /etc/haspuser/; \
		install -D -m 0644 $(TMP_FILES_DIR)/hasp.sh -t /etc/profile.d/; \
		systemctl enable hasp_monitor; \
	'