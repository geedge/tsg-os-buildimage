export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL

.PHONY: all chroot-commands

all: chroot-commands

chroot-commands:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		install -D -m 0755 $(TMP_FILES_DIR)/clean_orphaned_pods_dir.sh -t /opt/tsg/k3s/scripts/; \
		install -D -m 0644 $(TMP_FILES_DIR)/k3s-orphaned-pods-dir-clean.service /usr/lib/systemd/system/; \
		install -D -m 0644 $(TMP_FILES_DIR)/k3s-orphaned-pods-dir-clean.timer /usr/lib/systemd/system/; \
		systemctl enable k3s-orphaned-pods-dir-clean.timer; \
	'
