# Some paths are definitely not strictly false paths
# (E.g., the status vector that goes into the Axi registers)
# is not properly synchronized.
#
# Then there are the paths that are constrained with 'max delay'
# in the IP xdc (through drp_ipif_i...). Even in the example design
# the source and destination clocks (dclk - which is the DRP clock
# I assume) and coreclk are independent and possibly unrelated.
# This means that the max delay makes no sense. There seem to
# be synchronizers (concluding from some net names only) and maybe a
# false path is OK ?
#
# ...Shrug...
set_false_path -from [get_clocks ethRefClk] -to [get_clocks txClockGt]
