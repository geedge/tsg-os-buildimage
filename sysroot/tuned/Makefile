export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL

.PHONY: x86_64_COTS AArch64_COTS install

x86_64_COTS: install_x86_64

AArch64_COTS: install_AArch64

install_x86_64:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		install -D -m 0644 $(TMP_FILES_DIR)/tuned.conf -t /etc/tuned/tsg-os-cpu-partitioning/; \
		cd /usr/lib/python3.6/site-packages && patch -p1 -t < $(TMP_FILES_DIR)/371.patch || true; \
		tuned-adm profile tsg-os-cpu-partitioning; \
		sed -i "s/After=/&tsg-os-HAL.service /" /usr/lib/systemd/system/tuned.service \
	'

install_AArch64:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		install -D -m 0644 $(TMP_FILES_DIR)/tuned.conf -t /etc/tuned/tsg-os-cpu-partitioning/; \
		cd /usr/lib/python3.9/site-packages && patch -p1 -t < $(TMP_FILES_DIR)/371.patch || true; \
		tuned-adm profile tsg-os-cpu-partitioning; \
		sed -i "s/After=/&tsg-os-HAL.service /" /usr/lib/systemd/system/tuned.service \
	'