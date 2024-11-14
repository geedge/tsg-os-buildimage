export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL
export KERNEL_RELEASE

.PHONY: AArch64_COTS install_AArch64 x86_64_COTS

x86_64_COTS:

AArch64_COTS: install

install:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		cp $(TMP_FILES_DIR)/qemu-x86_64.conf /usr/lib/binfmt.d/; \
		cp $(TMP_FILES_DIR)/qemu-x86_64-static /usr/bin/qemu-x86_64-static; \
		chmod +x /usr/bin/qemu-x86_64-static; \
	'