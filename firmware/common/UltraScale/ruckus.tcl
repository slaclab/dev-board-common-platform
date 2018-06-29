# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load Source Code
loadSource -dir  "$::DIR_PATH/rtl/"
# Recent (2018.1) vivado warns that loading OOC DCPs is not
# recommended and .xci should be used...
#
#loadSource -path "$::DIR_PATH/ip/SystemManagementCore.dcp"
loadIpCore  -path "$::DIR_PATH/ip/SystemManagementCore.xci"
