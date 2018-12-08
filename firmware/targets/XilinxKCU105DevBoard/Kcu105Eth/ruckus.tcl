# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(PROJ_DIR)/../../../

# Load local source Code and constraints
loadSource      -dir  "$::DIR_PATH/hdl/"
loadConstraints -path "$::DIR_PATH/hdl/Kcu105Eth.xdc"
loadConstraints -path "$::DIR_PATH/hdl/ddr4_pins.xdc"
loadConstraints -path "$::DIR_PATH/hdl/iic_pins.xdc"
if { [info exists ::env(DISABLE_10G_ETH)] != 1 || $::env(DISABLE_10G_ETH) == 0  } {
	loadConstraints -path "$::DIR_PATH/hdl/TenGigEth.xdc"
	loadConstraints -path "$::DIR_PATH/hdl/TenGigEthClockGroups.xdc"
	loadConstraints -path "$::DIR_PATH/hdl/TenGigEthGthUltraScale156p25MHzCore.xdc"
	loadConstraints -path "$::DIR_PATH/hdl/TenGigEthGthUltraScale156p25MHzCore_clocks.xdc"
	loadConstraints -path "$::DIR_PATH/hdl/TenGigEthGthUltraScale156p25MHzCore_gt.xdc"
	loadConstraints -path "$::DIR_PATH/hdl/TenGigEthFalsePath.xdc"

	set_property PROCESSING_ORDER  LATE  [get_files "$::DIR_PATH/hdl/TenGigEthClockGroups.xdc"]
}

loadConstraints -path "$::DIR_PATH/hdl/Kcu105EthClockGroups.xdc"

# process after any library modules have added generated clocks
set_property PROCESSING_ORDER  LATE  [get_files "$::DIR_PATH/hdl/Kcu105EthClockGroups.xdc"]

if { [llength [get_ips ddr4_0]] == 0 } {
	create_ip -name ddr4 -vendor xilinx.com -library ip -version 2.2 -module_name ddr4_0
    set_property -dict [ list \
		CONFIG.C0.DDR4_TimePeriod       {1250} \
		CONFIG.C0.DDR4_InputClockPeriod {3333} \
		CONFIG.C0.DDR4_CLKOUT0_DIVIDE   {7} \
		CONFIG.C0.DDR4_MemoryPart       {EDY4016AABG-DR-F} \
		CONFIG.C0.DDR4_DataWidth        {64} \
		CONFIG.C0.DDR4_AxiSelection     {true} \
		CONFIG.C0.DDR4_CasLatency       {11} \
		CONFIG.C0.DDR4_CasWriteLatency  {11} \
		CONFIG.C0.DDR4_AxiDataWidth     {512} \
		CONFIG.C0.DDR4_AxiAddressWidth  {31} \
		CONFIG.C0.BANK_GROUP_WIDTH      {1} \
		CONFIG.Debug_Signal             {Enable} \
		CONFIG.System_Clock             {No_Buffer} \
		] [get_ips ddr4_0]
}
