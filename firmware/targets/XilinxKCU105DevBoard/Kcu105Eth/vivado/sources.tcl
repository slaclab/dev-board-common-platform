# Override default of 'top' property so they can rename project variants
set_property top Kcu105Eth [current_fileset]

# Append top-level generics set from Makefile variables
set genericArgList [get_property generic [current_fileset]]

if { [info exists ::env(DISABLE_10G_ETH)] == 1 } {
	lappend genericArgList "DISABLE_10G_ETH_G=$::env(DISABLE_10G_ETH)"
}

set_property generic ${genericArgList} -objects [current_fileset]

proc CreateLink { link target } {
    # NOTE: 'file exists xxx' doesn't detect a dangling symlink
    if { [catch {file type "$link"}] == 1 } {
		if { [file exists "$target"] == 0 } {
			# TCL refuses to create a dangling link which is what we want here...
			file mkdir "$target"
		}
		file link -symbolic "$link" "$target"
		if { [file isdirectory "$target"] == 1 } {
			file delete -force "$target"
		}
	}
}

# ruckus expects to find $(PROJECT).bit but vivado produces ${topLevel}.bit;
# create a symbolic link (which is at this time dangling)
if { [get_property top [current_fileset]] != "$::env(PROJECT)" } {
    CreateLink "$::env(IMPL_DIR)/$::env(PROJECT).bit"  "$::env(IMPL_DIR)/[get_property top [current_fileset]].bit"
}
