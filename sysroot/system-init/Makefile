export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL

#KERNEL_RELEASE := $(shell chroot $(CHROOT_DIR) uname -r)
KERNEL_RELEASE := 5.17.15-1.el8.x86_64

.PHONY: all chroot-commands

all: chroot-commands

chroot-commands:
	chroot $(CHROOT_DIR) bash -ec '\
		install -D -m 0644 $(TMP_FILES_DIR)/ipmi.conf /etc/sysconfig/ipmi; \
		systemctl enable ipmi; \
		install -D -m 0644 $(TMP_FILES_DIR)/watchdog.conf /etc/watchdog.conf; \
		systemctl enable watchdog; \
		systemctl enable irqbalance; \
		install -D -m 0644 $(TMP_FILES_DIR)/cpupower /etc/sysconfig/cpupower; \
		systemctl enable cpupower; \
		rm -rf /usr/lib/systemd/system/sysinit.target.wants/dev-hugepages.mount; \
		systemctl disable firewalld; \
		systemctl disable pmcd; \
		systemctl disable pmlogger; \
		systemctl disable pmie; \
		install -D -m 0644 $(TMP_FILES_DIR)/service_override_RuntimeMaxSec.conf -t /usr/lib/systemd/system/systemd-coredump@.service.d/; \
		systemctl disable sssd; \
		systemctl enable sshd; \
		systemctl enable chronyd; \
		install -D -m 0644 $(TMP_FILES_DIR)/chrony.conf -t /usr/lib/tmpfiles.d/; \
		systemctl disable ntpd; \
		systemctl enable snmpd; \
		systemctl enable snmptrapd; \
		systemctl disable abrt-ccpp; \
		systemctl disable abrt-oops; \
		systemctl disable abrtd; \
		systemctl disable dmraid-activation; \
		systemctl disable postfix; \
		sed -i "s/#UseDNS yes/UseDNS no/g" /etc/ssh/sshd_config; \
		echo "export MLX5_GLUE_PATH=/opt/tsg/mrzcpd/lib" >> /etc/profile; \
		echo "Defaults    env_keep += \"MLX5_GLUE_PATH\"" > /etc/sudoers.d/01-mrzcpd; \
		python3 -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple psutil; \
		sed -i "/^F! \/run\/nologin 0644/s/^/#/" /usr/lib/tmpfiles.d/systemd-nologin.conf; \
		pip2 install -i https://pypi.tuna.tsinghua.edu.cn/simple PrettyTable==0.7.2; \
		install -D -m 0755 $(TMP_FILES_DIR)/module-setup.sh -t /usr/lib/dracut/modules.d/99overlaymount/; \
		install -D -m 0755 $(TMP_FILES_DIR)/overlaymount.sh -t /usr/lib/dracut/modules.d/99overlaymount/; \
		dracut --force -v /boot/initramfs-$(KERNEL_RELEASE).img $(KERNEL_RELEASE); \
		python3 -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple toml; \
		python3 -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple sdnotify; \
	'