export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL

.PHONY: all chroot-commands

all: chroot-commands

chroot-commands:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		install -D -m 0644 $(TMP_FILES_DIR)/01-add-no-auto-default.conf -t /usr/lib/NetworkManager/conf.d/; \
	'
