export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL

.PHONY: x86_64_COTS AArch64_COTS install_x86_64 install_AArch64

x86_64_COTS: install_x86_64

AArch64_COTS: install_AArch64

install_x86_64:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		install -D -m 0644 $(TMP_FILES_DIR)/* -t /usr/lib/python3.6/site-packages/sos/report/plugins/; \
	'

install_AArch64:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		install -D -m 0644 $(TMP_FILES_DIR)/* -t /usr/lib/python3.9/site-packages/sos/report/plugins/; \
	'