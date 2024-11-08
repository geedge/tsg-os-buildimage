export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL

.PHONY: all chroot-commands

all: chroot-commands

chroot-commands:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		install -D -m 0644 $(TMP_FILES_DIR)/90-tsg-os.conf -t /usr/lib/sysctl.d/; \
		install -D -m 0644 $(TMP_FILES_DIR)/80-proxy.conf -t /usr/lib/sysctl.d/; \
	'
