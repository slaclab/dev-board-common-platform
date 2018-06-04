# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

if { [llength [get_ips Ila_256]] == 0 } {
	create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name Ila_256
	set_property -dict [list CONFIG.C_PROBE0_WIDTH {64} CONFIG.C_PROBE1_WIDTH {64} CONFIG.C_PROBE2_WIDTH {64} CONFIG.C_PROBE3_WIDTH {64} CONFIG.C_NUM_OF_PROBES {4} ] [get_ips Ila_256]
}

# Load Source Code
loadSource -dir  "$::DIR_PATH/rtl/"
