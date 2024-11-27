export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL

.PHONY: x86_64_COTS AArch64_COTS install

x86_64_COTS: install

AArch64_COTS: install

install:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		install -D -m 0755 $(TMP_FILES_DIR)/bin/* -t /bin/; \
		install -D -m 0755 $(TMP_FILES_DIR)/lib/* -t /lib/onie/; \
	'
