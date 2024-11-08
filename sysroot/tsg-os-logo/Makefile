export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL

#KERNEL_RELEASE := $(shell chroot $(CHROOT_DIR) uname -r)
KERNEL_RELEASE := 5.17.15-1.el8.x86_64

.PHONY: all chroot-commands

all: chroot-commands

chroot-commands:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		install -D -m 0755 /usr/bin/uname /usr/bin/uname-backup; \
		install -D -m 0755 $(TMP_FILES_DIR)/uname /usr/bin/uname; \
		sed -i -e 's/KERNEL_RELEASE/$(KERNEL_RELEASE)/' /usr/bin/uname; \
		mkdir -p /usr/share/plymouth/themes/fedora-plymouth/;\
		tar -zxvf $(TMP_FILES_DIR)/tsg-os-plymouth-theme.tar.gz -C /usr/share/plymouth/themes/; \
		dnf -y install plymouth-plugin-script; \
		plymouth-set-default-theme -R fedora-plymouth; \
		install -D -m 0755 /usr/bin/uname-backup /usr/bin/uname; \
	'
