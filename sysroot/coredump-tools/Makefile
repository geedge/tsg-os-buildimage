export CHROOT_DIR
export CHROOT_SHELL

.PHONY: x86_64_COTS AArch64_COTS install

x86_64_COTS: install

AArch64_COTS: install

install:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		dnf -y install coredump-tools-1.1.2-70125ea; \
		sed -i -E "s/^(.*Defaults    secure_path =.*)$$/\1:\/opt\/tsg\/coredump\/bin/" /etc/sudoers; \
	'