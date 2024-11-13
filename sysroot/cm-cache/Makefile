export CHROOT_DIR
export CHROOT_SHELL

.PHONY: x86_64_COTS AArch64_COTS install

x86_64_COTS: install

AArch64_COTS: install

install:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		sed -ie "s/^cm_local_cache_chart_name=.*/cm_local_cache_chart_name=redis-7.2.4.tgz/g" \
			/opt/tsg/clixon/etc/mgnt-srv.conf;\
		sed -ie "s/^sd_local_cache_chart_name=.*/sd_local_cache_chart_name=redis-7.2.4.tgz/g" \
			/opt/tsg/clixon/etc/mgnt-srv.conf;\
	'