
# Define target output
target: prom

# You can rename the project (e.g., if you build different variants
# from the same Makefile and source tree). Ruckus will print a fat
# warning but that can be ignored...
#
#export PROJECT=MyProject

# Define Firmware Version Number
export PRJ_VERSION = 0x00000001

# Define target part
export PRJ_PART = XCKU040-FFVA1156-2-E

# Define the Microblaze source path
#export SDK_SRC_PATH = $(PROJ_DIR)/../../../common/core/src

# Whether to use the on-board PHY (connected to the RJ-45 jack)
# or an SFP module for ethernet connectivity.
# Must be true or false
export INCLUDE_ETH_SGMII_LVDS = 1

export REMOVE_UNUSED_CODE = 1

# Using a non-standard target directory structure,
# which requires me to define the TOP_DIR path
export TOP_DIR = $(abspath $(PWD)/../../..)

# You can disable the 10G Ethernet support (e.g., if you need the SFP
# for your project) by setting this variable to a nonzero value:
#
# export DISABLE_10G_ETH=1
#

# Use top level makefile
include $(TOP_DIR)/submodules/ruckus/system_vivado.mk

.PHONY: clean-config

clean: clean-config

clean-config:
	$(RM) config/defaults.yaml

$(SOURCE_DEPEND): $(IMPL_DIR)

$(IMPL_DIR):
	mkdir -p $@

yaml $(SOURCE_DEPEND): config/defaults.yaml

# Application may add more 'defaults' snippets here
config/defaults.yaml: Makefile
	$(RM) $@
	echo '# THIS FILE WAS AUTOMATICALLY GENERATED -- DO NOT EDIT' >> $@
	echo '#'                           >> $@
	echo '#include defaults_top.yaml'  >> $@
