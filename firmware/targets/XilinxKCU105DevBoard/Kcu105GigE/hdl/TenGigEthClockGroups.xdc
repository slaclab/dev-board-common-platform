# process clock groups late (after any library xdcs might have added generated clocks!)
#
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {ethRefClk}]

