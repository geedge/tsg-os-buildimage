export CHROOT_DIR
export CHROOT_SHELL

.PHONY: x86_64_COTS AArch64_COTS install

x86_64_COTS: install

AArch64_COTS: install

install:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		dnf -y install libyaml; \
		ln -vfs /lib64/libyaml-0.so.2.0.5 /usr/lib64/libyaml.so; \
		pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple jinja-cli; \
		dnf -y install cligen-5.8.0-release clixon-5.8.4-6462458 tsg-os-mgnt-srv-1.2.50.233e507; \
		systemctl enable tsg-clixon-backend; \
		systemctl enable tsg-clixon-restconf; \
	'