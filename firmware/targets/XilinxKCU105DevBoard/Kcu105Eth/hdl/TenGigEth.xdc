create_clock -name ethRefClk   -period 6.4        [get_ports {refClkP[0]}]

set_false_path -from [get_ports {gpioDip[3]}]

set_property PACKAGE_PIN U4 [get_ports "sfpTxP[0]"]
set_property PACKAGE_PIN U3 [get_ports "sfpTxN[0]"]
set_property PACKAGE_PIN T2 [get_ports "sfpRxP[0]"]
set_property PACKAGE_PIN T1 [get_ports "sfpRxN[0]"]
