if { [file exists $::env(IMPL_DIR)/runme.log] == 0 || [CheckImpl 1] != true } {
	SourceTclFile $::env(VIVADO_DIR)/debug.tcl
}
