export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL

.PHONY: all chroot-commands

all:  chroot-commands

chroot-commands:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		tar -zcvf $(TMP_FILES_DIR)/patch.tar.gz -C $(TMP_FILES_DIR)/patch/ .; \
		cat $(TMP_FILES_DIR)/install.sh $(TMP_FILES_DIR)/patch.tar.gz > $(TMP_FILES_DIR)/tsg-os_9000-NPB-P01R01_patch.bin; \
		chmod 0755 $(TMP_FILES_DIR)/tsg-os_9000-NPB-P01R01_patch.bin; \
		mkdir -p /tmp/9000_NPB/; cp $(TMP_FILES_DIR)/tsg-os_9000-NPB-P01R01_patch.bin  /tmp/9000_NPB/; \
	'