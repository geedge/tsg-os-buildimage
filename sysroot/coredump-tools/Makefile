export CHROOT_DIR
export CHROOT_SHELL

.PHONY: all chroot-commands

all: chroot-commands

chroot-commands:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		dnf -y install coredump-tools-1.1.1-291df81; \
		sed -i -E "s/^(.*Defaults    secure_path =.*)$$/\1:\/opt\/tsg\/coredump\/bin/" /etc/sudoers; \
	'