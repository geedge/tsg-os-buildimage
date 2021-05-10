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

PROJECTDIR		=  $(abspath )
BUILDDIR_BASE	=  $(abspath ./build)
IMAGEDIR_BASE	=  $(abspath ./images)

OS_RELEASE_VER = 20.04.1

ifndef PROFILE_LIST
PROFILE_LIST := 9000NPBP01R01
endif

export TOOLSDIR
export CONFDIR
export INSTALLERDIR
export PROJECTDIR
export BUILDDIR_BASE
export IMAGEDIR_BASE
export OS_RELEASE_VER

.PHONY: all clean $(PROFILE_LIST)

all: $(PROFILE_LIST)
	mkdir -p $(BUILDDIR_BASE)
	mkdir -p $(IMAGEDIR_BASE)

	$(Q) echo "=== Building $< $(OS_RELEASE_VER) ==="
	$(Q) $(MAKE) -f make/Makefile.$< all

clean: $(PROFILE_LIST)
	$(Q) echo "=== Finished making $@ for $(PLATFORM) ==="