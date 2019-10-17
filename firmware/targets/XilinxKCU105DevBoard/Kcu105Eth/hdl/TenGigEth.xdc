create_clock -name ethRefClk   -period 6.4        [get_ports {refClkP[0]}]

set_false_path -from [get_ports {gpioDip[3]}]
# txClockGt is generated from 2*ethRefClk by dividing by two.
# Since the phase of the divider is unknown vivado assumes the
# clocks to be unrelated and reports them as 'unsafe' (no common node).
# All data is sent through synchronizers (last time I checked;
# excepts for a few slow status bits for which I'll create a
# pull request: surf commit 15cd9edbb1aa0da0dbf7e58b975dbe98f925bbb0...)
set_false_path -from [get_clocks ethRefClk] -to [get_clocks txClockGt]

set_property PACKAGE_PIN U4 [get_ports "sfpTxP[0]"]
set_property PACKAGE_PIN U3 [get_ports "sfpTxN[0]"]
set_property PACKAGE_PIN T2 [get_ports "sfpRxP[0]"]
set_property PACKAGE_PIN T1 [get_ports "sfpRxN[0]"]
