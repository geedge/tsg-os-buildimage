export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL

.PHONY: all chroot-commands

all: chroot-commands

chroot-commands:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		dnf -y install freeipmi --nogpgcheck; \
		install -D -m 0755 $(TMP_FILES_DIR)/systemd_exporter -t /opt/tsg/exporter/; \
		install -D -m 0644 $(TMP_FILES_DIR)/exporter-systemd.service -t /usr/lib/systemd/system/; \
		systemctl enable exporter-systemd; \
	'