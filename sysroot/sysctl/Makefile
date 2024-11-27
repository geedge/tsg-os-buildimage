export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL

.PHONY: x86_64_COTS AArch64_COTS install install_io_uring_disabled

x86_64_COTS: install

AArch64_COTS: install install_io_uring_disabled

install:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		install -D -m 0644 $(TMP_FILES_DIR)/50-coredump.conf -t /usr/lib/sysctl.d/; \
		install -D -m 0644 $(TMP_FILES_DIR)/90-tsg-os.conf -t /usr/lib/sysctl.d/; \
		install -D -m 0644 $(TMP_FILES_DIR)/80-proxy.conf -t /usr/lib/sysctl.d/; \
	'

install_io_uring_disabled:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		install -D -m 0644 $(TMP_FILES_DIR)/80-proxy-io_uring_disabled.conf -t /usr/lib/sysctl.d/; \
	'
