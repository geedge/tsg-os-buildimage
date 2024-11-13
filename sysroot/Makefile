export CHROOT_DIR
export MACHINE_ID

CHROOT_SHELL := "bash -exc"
KERNEL_RELEASE := $(shell chroot $(CHROOT_DIR) readlink /boot/initrd.img | sed 's/^initramfs-//;s/\.img$$//')

#COMPONENT_DIRS := $(shell find . -maxdepth 1 -type d ! -name "build" ! -name "." | sed 's|^\./||')
COMPONENT_DIRS := coredump-tools clixon cm-cache exporter hasp k3s k3s-cleaner nm-config OFED patches-9000-NPB sosreport sysctl system-init helm tsg-diagnose tsg-os-HAL tsg-os-logfile-cleaner tsg-os-logo tsg-os-oobc tuned

.PHONY: all clean $(COMPONENT_DIRS)

all: $(COMPONENT_DIRS)

$(COMPONENT_DIRS):
	@mkdir -p $(CHROOT_DIR)/tmp/$@; cp -arf $@/* $(CHROOT_DIR)/tmp/$@
	@$(MAKE) -C $@ CHROOT_DIR=$(abspath $(CHROOT_DIR)) CHROOT_SHELL=$(CHROOT_SHELL) TMP_FILES_DIR=/tmp/$@/files KERNEL_RELEASE=$(KERNEL_RELEASE) $(MACHINE_ID)
	@rm -rf $(CHROOT_DIR)/tmp/$@
clean:
	rm -rf $(BUILD_DIR)