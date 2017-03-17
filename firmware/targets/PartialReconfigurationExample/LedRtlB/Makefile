
# Define target output
target: bit_dynamic

# Define target part
export PRJ_PART = XC7K325TFFG900-2

# Declare the static checkpoint
export RECONFIG_CHECKPOINT = $(PROJ_DIR)/../StaticDesign/images/StaticDesign_10000000_static.dcp

# List of build core directories.
export MODULE_DIRS = $(PROJ_DIR)/../../modules/StdLib  \
                     $(PROJ_DIR)

# Max number of smart explorer runs
export SMART_MAX_RUNS = 10

# Use top level makefile
include ../../modules/StdLib/build/system_vivado_v1.mk
