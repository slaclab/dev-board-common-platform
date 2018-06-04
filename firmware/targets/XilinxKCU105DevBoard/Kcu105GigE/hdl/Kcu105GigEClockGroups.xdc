
# process these clock groups late (after any library xdcs might have added generated clocks!)

set_clock_groups -physically_exclusive -group lcls1RefClk -group lcls2RefClk

set_clock_groups -asynchronous -group [get_clocks {jesdClk jesdClk2x jesdUsrClk}]
set_clock_groups -asynchronous -group [get_clocks {sysClk156MHz}]
set_clock_groups -asynchronous -group [get_clocks {sysClk300P}]
set_clock_groups -asynchronous -group [get_clocks {dnaClk}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {lcls1RefClk}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {lcls2RefClk}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {sgmiiClkP}]
