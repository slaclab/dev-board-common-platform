# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load Source Code
loadSource -path "$::DIR_PATH/rtl/AxiLiteExample.vhd"
loadSource -path "$::DIR_PATH/vivado_hls/ip/AxiLiteExampleCore.dcp"
