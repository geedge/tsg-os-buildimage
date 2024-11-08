export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL

.PHONY: all chroot-commands

all: chroot-commands

chroot-commands:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		install -D -m 0644 $(TMP_FILES_DIR)/tsg-os-logfile-cleaner.service -t /usr/lib/systemd/system/; \
		install -D -m 0644 $(TMP_FILES_DIR)/logfile-cleaner.py -t /opt/tsg/logfile-cleaner/bin/; \
		install -D -m 0644 $(TMP_FILES_DIR)/config.toml -t /opt/tsg/logfile-cleaner/etc/; \
		install -D -m 0644 $(TMP_FILES_DIR)/tsg-os-logfile-cleaner.sh -t /etc/profile.d/; \
		systemctl enable tsg-os-logfile-cleaner; \
	'
