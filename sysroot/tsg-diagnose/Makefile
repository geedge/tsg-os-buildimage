export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL

.PHONY: x86_64_COTS AArch64_COTS install

x86_64_COTS: install

AArch64_COTS: install

install:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		dnf -y install tsg-diagnose-2.0.10.4d80fdf --nogpgcheck; \
		sed -i -E "s/^(.*Defaults    secure_path =.*)$$/\1:\/opt\/tsg\/tsg-diagnose\/scripts/" /etc/sudoers; \
		install -D -m 0644 /opt/tsg/tsg-diagnose/k8s-resource/* -t /var/lib/rancher/k3s/server/manifests/; \
		mkdir -p /var/lib/rancher/k3s/agent/images/;\
		if ls /opt/tsg/tsg-diagnose/images/*.tar 1> /dev/null 2>&1; then \
			mv /opt/tsg/tsg-diagnose/images/* /var/lib/rancher/k3s/agent/images/; \
		fi;\
		install -D -m 0755 $(TMP_FILES_DIR)/30-add_dign_br_iptable_rule.sh -t /etc/NetworkManager/dispatcher.d/; \
		install -D -m 0644 $(TMP_FILES_DIR)/99-tsg-dign.rules -t /usr/lib/udev/rules.d/ \
	'
