
# Define target output
target: bit_static

# List of Reconfigurable RTL Block Names.
export RECONFIG_NAME = LedRtlA \
                       LedRtlB

# Define target part
export PRJ_PART = XC7K325TFFG900-2

# List of build core directories.
export MODULE_DIRS = $(PROJ_DIR)/../../modules/StdLib  \
                     $(PROJ_DIR)

# Max number of smart explorer runs
export SMART_MAX_RUNS = 10

# Use top level makefile
include ../../modules/StdLib/build/system_vivado_v1.mk
