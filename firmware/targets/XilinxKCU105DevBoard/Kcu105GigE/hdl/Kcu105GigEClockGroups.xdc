
# process these clock groups late (after any library xdcs might have added generated clocks!)
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {sysClk300P}] -group [get_clocks -include_generated_clocks {gtClkP}] -group [get_clocks -include_generated_clocks {sgmiiClkP}]

