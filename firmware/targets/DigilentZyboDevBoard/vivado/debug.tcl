open_run synth_1

CreateDebugCore ila1
SetDebugCoreClk ila1 [get_nets -of [get_clocks clk_fpga_0]]

ConfigProbe ila1 [get_nets {axilReadSlave[arready]}]
ConfigProbe ila1 [get_nets {axilReadSlave[rvalid]}]
ConfigProbe ila1 [get_nets {axilReadSlave[rdata]*}]
ConfigProbe ila1 [get_nets {M_AXI_GP0_RREADY}]

ConfigProbe ila1 [get_nets {M_AXI_GP0_ARVALID}]
ConfigProbe ila1 [get_nets {M_AXI_GP0_ARADDR*}]

WriteDebugProbes ila1
