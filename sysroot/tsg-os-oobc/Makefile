export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL

.PHONY: x86_64_COTS AArch64_COTS install

x86_64_COTS: install

AArch64_COTS: install

install:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		install -D -m 0755 $(TMP_FILES_DIR)/tsg-os-oobc.sh -t /etc/profile.d/; \
		install -D -m 0755 $(TMP_FILES_DIR)/tsg-os-oobc-done -t /opt/tsg/tools/tsg-os-oobc/; \
		install -D -m 0644 $(TMP_FILES_DIR)/service_enabled_after_oobc_done.conf -t /usr/lib/systemd/system/k3s.service.d/; \
		install -D -m 0644 $(TMP_FILES_DIR)/service_enabled_after_oobc_done.conf -t /usr/lib/systemd/system/hasp_monitor.service.d/; \
		install -D -m 0644 $(TMP_FILES_DIR)/service_enabled_after_oobc_done.conf -t /usr/lib/systemd/system/tsg-clixon-backend.service.d/; \
		install -D -m 0644 $(TMP_FILES_DIR)/service_enabled_after_oobc_done.conf -t /usr/lib/systemd/system/tsg-clixon-restconf.service.d/; \
		touch /var/lib/.tsg-os-oobc-enable \
	'


