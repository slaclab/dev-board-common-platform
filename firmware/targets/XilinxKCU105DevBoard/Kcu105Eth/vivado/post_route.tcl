source -quiet $::env(RUCKUS_DIR)/vivado_env_var.tcl
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

set topLevel [get_property top [current_fileset]]

# ruckus expects to find $(PROJECT).bit but vivado produces ${topLevel}.bit;
# just copy...
if { "{topLevel}" != "$::env(PROJECT)" } {
	file copy -force $::env(IMPL_DIR)/${topLevel}.bit $::env(IMPL_DIR)/$::env(PROJECT).bit
}

