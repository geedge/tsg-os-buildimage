export CHROOT_DIR
export TMP_FILES_DIR
export CHROOT_SHELL

.PHONY: x86_64_COTS AArch64_COTS install

x86_64_COTS: install

AArch64_COTS: install

#git clone --depth 1 https://github.com/brendangregg/FlameGraph.git /opt/tools/FlameGraph/
#git clone --depth 1 https://github.com/brendangregg/perf-tools.git /opt/tools/perf-tools/
install:
	chroot $(CHROOT_DIR) $(CHROOT_SHELL) '\
		mkdir -p /opt/tsg/tools/; \
		tar -zxvf $(TMP_FILES_DIR)/FlameGraph.tar.gz -C /opt/tsg/tools/; \
		tar -zxvf $(TMP_FILES_DIR)/perf-tools.tar.gz -C /opt/tsg/tools/; \
		install -D -m 0755 $(TMP_FILES_DIR)/run_flamegrah.sh -t /opt/tsg/tools/; \
	'