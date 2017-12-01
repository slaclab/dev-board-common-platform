# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(PROJ_DIR)/../../../

# Load local source Code and constraints
loadSource      -dir "$::DIR_PATH/hdl/"
loadConstraints -dir "$::DIR_PATH/hdl/"

# process after any library modules have added generated clocks
set_property PROCESSING_ORDER LATE [get_files "$::DIR_PATH/hdl/Kcu105GigEClockGroups.xdc"]
