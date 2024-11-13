export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL

.PHONY: x86_64_COTS AArch64_COTS install

x86_64_COTS: install

AArch64_COTS: install

install:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		install -D -m 0755 $(TMP_FILES_DIR)/script/* -t /opt/tsg/tsg-os-HAL/scripts/; \
		dnf -y install numactl; \
		install -D -m 0644 $(TMP_FILES_DIR)/service/tsg-os-HAL.service -t /usr/lib/systemd/system/; \
		systemctl enable tsg-os-HAL.service; \
		install -D -m 0644 $(TMP_FILES_DIR)/conf/tsg-os-HAL.conf -t	/etc/sysconfig/; \
		install -D -m 0644 $(TMP_FILES_DIR)/timer.d/timer_override_oncalendar.conf -t /usr/lib/systemd/system/fstrim.timer.d/; \
		systemctl enable fstrim.timer \
	'
