export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL

# Architecture specific variables
AKSUSBD_RPM_X86 = aksusbd-8.31-1.x86_64.rpm
AKSUSBD_RPM_ARM = aksusbd-8.31-1.aarch64.rpm

.PHONY: x86_64_COTS AArch64_COTS install-aksusbd-x86_64 install-aksusbd-aarch64 install-common

# Architecture specific targets
x86_64_COTS: install-aksusbd-x86_64 install-common

AArch64_COTS: install-aksusbd-aarch64 install-common

# Install aksusbd for x86_64
install-aksusbd-x86_64:
    chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
        dnf -y install $(TMP_FILES_DIR)/$(AKSUSBD_RPM_X86) --nogpgcheck; \
        systemctl disable aksusbd; \
    '

# Install aksusbd for aarch64
install-aksusbd-aarch64:
    chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
        dnf -y install $(TMP_FILES_DIR)/$(AKSUSBD_RPM_ARM) --nogpgcheck; \
        systemctl disable aksusbd; \
    '

# Common installation steps
install-common:
    chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
        dnf -y install hasp-tools-1.0.14.54d3e89 --nogpgcheck; \
        install -D -m 0644 $(TMP_FILES_DIR)/service_override_env.conf -t /usr/lib/systemd/system/hasp_monitor.service.d/; \
        install -D -m 0644 $(TMP_FILES_DIR)/hasp_25743.ini -t /etc/haspuser/; \
        install -D -m 0644 $(TMP_FILES_DIR)/hasp.sh -t /etc/profile.d/; \
        systemctl enable hasp_monitor; \
    '