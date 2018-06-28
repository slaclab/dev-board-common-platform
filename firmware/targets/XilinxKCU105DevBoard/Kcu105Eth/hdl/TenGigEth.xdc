create_clock -name ethRefClk   -period 6.4        [get_ports {refClkP[0]}]

set_false_path -from [get_ports {gpioDip[3]}]
