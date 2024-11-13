export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL
export KERNEL_RELEASE

.PHONY: x86_64_COTS AArch64_COTS install

x86_64_COTS: install

AArch64_COTS: install

install:
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
