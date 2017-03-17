# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load Source Code
loadSource -path "rtl/AxiLiteExample.vhd"
loadSource -path "vivado_hls/ip/AxiLiteExampleCore.dcp"
