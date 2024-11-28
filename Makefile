#-------------------------------------------------------------------------------
#
#  Copyright (C) 2020 Lu Qiuwen <luqiuwen@geedgenetworks.com>
#  SPDX-License-Identifier:     GPL-2.0
#
#  Builds the TSG-OS (Tiango Security Gateway OS) install images

# Don't move this, it must be in FRONT of any included makefiles


THIS_MAKEFILE = $(realpath $(firstword $(MAKEFILE_LIST)))
SHELL = bash

V ?= 0
Q = @
ifneq ($V,0)
	Q =
endif

PATCHDIR     = $(realpath ./patches)
UPSTREAMDIR  = $(realpath ./upstream)
CONFDIR	     = $(realpath ./conf)
TOOLSDIR     = $(realpath ./tools)
INSTALLERDIR = $(realpath ./installer)

PROJECTDIR		=  $(abspath ./)
BUILDDIR_BASE	=  $(abspath ./build)
IMAGEDIR_BASE	=  $(abspath ./images)

CREATE_BUILD_DIR_TMP := $(shell mkdir -p $(BUILDDIR_BASE))
CREATE_IMAGE_DIR_TMP := $(shell mkdir -p $(IMAGEDIR_BASE))

# autorevision
REVISON_TMP := $(shell $(TOOLSDIR)/autorevision.sh -t sh > $(BUILDDIR_BASE)/version.make)
include $(BUILDDIR_BASE)/version.make

ifeq ($(DALIY_BUILD_VERSION),1)
VCS_TAG="0.0.0"
endif

OS_BUILD_TIME := $(VCS_DATE)
OS_BUILD_TIME := $(subst -,$e,$(OS_BUILD_TIME))
OS_BUILD_TIME := $(subst :,$e,$(OS_BUILD_TIME))
OS_BUILD_TIME := $(subst T,$e,$(OS_BUILD_TIME))
OS_BUILD_TIME := $(subst Z,$e,$(OS_BUILD_TIME))
OS_BUILD_TIME := $(subst ",$e,$(OS_BUILD_TIME))
OS_BUILD_TIME := $(subst +,$e,$(OS_BUILD_TIME))

OS_BUILD_HASH    := $(subst ",$e,$(VCS_SHORT_HASH))
OS_BUILD_TAG     := $(subst ",$e,$(VCS_TAG))

ifeq ($(CI_COMMIT_BRANCH),)
	OS_BUILD_BRANCH  := $(subst -,_,$(VCS_BRANCH))
else
	OS_BUILD_BRANCH  := $(subst -,_,$(CI_COMMIT_BRANCH))
endif

ifeq ($(OS_BUILD_TAG),)
	OS_BUILD_TAG := $(OS_BUILD_TIME)
endif

ifeq ($(DALIY_BUILD_VERSION),1)
	OS_RELEASE_VER = $(OS_BUILD_BRANCH)-$(OS_BUILD_TIME)-$(OS_BUILD_HASH)
else
	OS_RELEASE_VER = $(OS_BUILD_TAG)-$(OS_BUILD_HASH)
endif

ifeq ($(DALIY_BUILD_VERSION),1)
	RESULT_BRANCH_MATCH = $(shell echo $(OS_BUILD_BRANCH) | sed -n "/\(dev\|rel\)-[0-9][0-9].[0-9][0-9]/p")
	ifeq ($(OS_BUILD_BRANCH),$(RESULT_BRANCH_MATCH))
		BRANCH_VER		= $(shell echo $(OS_BUILD_BRANCH) | sed 's/\(dev\|rel\)-//g')
		BRANCH_PREFIX	= $(shell echo $(OS_BUILD_BRANCH) | sed 's/-[0-9][0-9].[0-1][0-9]//g')
		HELM_CHART_VER	= $(BRANCH_VER)-$(BRANCH_PREFIX)-$(OS_BUILD_TIME)+$(OS_BUILD_HASH)
	else
		BRANCH_NAME_VER	= $(shell echo $(OS_BUILD_BRANCH) | sed 's/[^A-Za-z0-9-]\+/-/g')
		HELM_CHART_VER	=  0.1.0-$(BRANCH_NAME_VER)-$(OS_BUILD_TIME)+$(OS_BUILD_HASH)
	endif
else
		TAG_VER			= $(shell echo $(OS_BUILD_TAG) | sed 's/^\(v\|V\)//g')
		HELM_CHART_VER	= $(TAG_VER)+$(OS_BUILD_HASH)
endif

ifndef PROFILE_LIST
PROFILE_LIST := 7400MCN0P01R01
endif

ifndef LOCK_STATE
LOCK_STATE := UNLOCKED
endif

ifndef ENABLE_LICENSE_PROTECTED
ENABLE_LICENSE_PROTECTED := 0
endif

ifndef ENABLE_LICENSE_PROTECTED
ENABLE_ALIYUN_INTERNAL_DOMAIN := 0
endif

export TOOLSDIR
export CONFDIR
export INSTALLERDIR
export PROJECTDIR
export BUILDDIR_BASE
export IMAGEDIR_BASE
export OS_RELEASE_VER
export LOCK_STATE
export HELM_CHART_VER
export ENABLE_LICENSE_PROTECTED
export ENABLE_ALIYUN_INTERNAL_DOMAIN

.PHONY: all clean $(PROFILE_LIST)

all: $(PROFILE_LIST)
	$(Q) chmod 0755 $(TOOLSDIR)/*
	$(Q) sed -i -e 's/PULP_REPO_USERNAME/$(PULP_REPO_USERNAME)/g' $(CONFDIR)/yum-RockyLinux-8.conf
	$(Q) sed -i -e 's/PULP_REPO_PASSWORD/$(PULP_REPO_PASSWORD)/g' $(CONFDIR)/yum-RockyLinux-8.conf
	$(Q) sed -i -e 's/PULP_REPO_USERNAME/$(PULP_REPO_USERNAME)/g' $(CONFDIR)/yum-RockyLinux-9.conf
	$(Q) sed -i -e 's/PULP_REPO_PASSWORD/$(PULP_REPO_PASSWORD)/g' $(CONFDIR)/yum-RockyLinux-9.conf
ifeq ($(ENABLE_ALIYUN_INTERNAL_DOMAIN),1)
	$(Q) sed -i -e "s/mirrors.aliyun.com/mirrors.cloud.aliyuncs.com/" $(CONFDIR)/yum-RockyLinux-8.conf
	$(Q) sed -i -e "s/mirrors.aliyun.com/mirrors.cloud.aliyuncs.com/" $(CONFDIR)/yum-RockyLinux-9.conf
endif
	$(Q) echo "=== Building $< $(OS_RELEASE_VER) ==="
	$(Q) echo "=== Building chart version $< $(HELM_CHART_VER) ==="
	$(Q) $(MAKE) -f make/Makefile.$< all

clean: $(PROFILE_LIST)
	$(Q) echo "=== Finished making $@ for $(PLATFORM) ==="
