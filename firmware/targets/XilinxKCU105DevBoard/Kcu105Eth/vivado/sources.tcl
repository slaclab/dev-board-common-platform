# Override default of 'top' property so they can rename project variants
set_property top Kcu105Eth [current_fileset]

# Append top-level generics set from Makefile variables
set genericArgList [get_property generic [current_fileset]]

if { [info exists ::env(DISABLE_10G_ETH)] == 1 } {
	lappend genericArgList "DISABLE_10G_ETH_G=$::env(DISABLE_10G_ETH)"
}

set_property generic ${genericArgList} -objects [current_fileset]
