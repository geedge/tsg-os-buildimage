export CHROOT_DIR
export CHROOT_SHELL

.PHONY: x86_64_COTS AArch64_COTS install

x86_64_COTS: install

AArch64_COTS: install

install:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		dnf -y install libyaml; \
		pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple jinja-cli; \
		dnf -y install cligen-5.8.4.0528de8 clixon-5.8.8.648db44 tsg-os-mgnt-srv-1.2.50.233e507; \
		systemctl enable tsg-clixon-backend; \
		systemctl enable tsg-clixon-restconf; \
		sed -ie "s/^chart_name=.*/traffic-engine-$(HELM_CHART_VER).tgz/g" /opt/tsg/clixon/etc/mgnt-srv.conf; \
		sed -ie "s/^inject_adapter_chart_name=.*/inject-adapter-$(HELM_CHART_VER).tgz/g" /opt/tsg/clixon/etc/mgnt-srv.conf; \
		sed -ie "s/^mrzcpd_chart_name=.*/mrzcpd-$(HELM_CHART_VER).tgz/g" /opt/tsg/clixon/etc/mgnt-srv.conf; \
		sed -ie "s/^trex_chart_name=.*/trex-$(HELM_CHART_VER).tgz/g" /opt/tsg/clixon/etc/mgnt-srv.conf; \
		sed -ie "s/^datapath_trace_chart_name=.*/datapath-trace-$(HELM_CHART_VER).tgz/g" /opt/tsg/clixon/etc/mgnt-srv.conf; \
		sed -ie "s/^tsg_cm_chart_name=.*/tsg-cm-chart-0.1.0.tgz/g" /opt/tsg/clixon/etc/mgnt-srv.conf; \
	'