export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL
export KERNEL_RELEASE

.PHONY: x86_64_COTS AArch64_COTS install

x86_64_COTS: install
AArch64_COTS: install

install:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		if [ ! -f "/etc/pam.d/system-auth-local" ]; then \
			mv /etc/pam.d/system-auth /etc/pam.d/system-auth-local; \
			echo "session     required      pam_tty_audit.so  enable=*" >> /etc/pam.d/system-auth-local; \
			ln -vfs --relative /etc/pam.d/system-auth-local /etc/pam.d/system-auth; \
		fi; \
		if [ ! -f "/etc/pam.d/password-auth-local" ]; then \
			mv /etc/pam.d/password-auth /etc/pam.d/password-auth-local; \
			echo "session     required      pam_tty_audit.so  enable=*" >> /etc/pam.d/password-auth-local; \
			ln -vfs --relative /etc/pam.d/password-auth-local /etc/pam.d/password-auth; \
		fi; \
	'