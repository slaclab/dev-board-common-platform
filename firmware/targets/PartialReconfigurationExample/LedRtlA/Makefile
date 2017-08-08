export GIT_BYPASS = 1

# Define target output
target: prom

# Define the file path to the static checkpoint
export RECONFIG_CHECKPOINT = $(PROJ_DIR)/../StaticDesign/images/StaticDesign-0x00000001-20170808102834-ruckman-dirty_static.dcp

# Define hierarchical path to dynamic module
export RECONFIG_ENDPOINT = U_LedRtlA

# Define the PBLOCK name
export RECONFIG_PBLOCK = LED_A

# Define Firmware Version Number
export PRJ_VERSION = 0x00000001

# Define target part
export PRJ_PART = XC7K325TFFG900-2

# Using a non-standard target directory structure, 
# which requires me to define the TOP_DIR path
export TOP_DIR = $(abspath $(PWD)/../../..)

# Use top level makefile
include $(TOP_DIR)/submodules/ruckus/system_vivado.mk
