# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load the Core
loadRuckusTcl "$::DIR_PATH/AppTop"
loadSource -dir "$::DIR_PATH/lib"
loadRuckusTcl "$::DIR_PATH/VivadoHls"

if { file exists "$::DIR_PATH/core/ruckus.tcl" } {
    # use the user's AppCore if it's there
	loadRuckusTcl "$::DIR_PATH/core"
} else {
	# otherwise fall back on the stub
	loadRuckusTcl "$::DIR_PATH/coreStub"
}

# Get the family type
set family [getFpgaFamily]

if { ${family} == "artix7" } {
   loadRuckusTcl "$::DIR_PATH/7Series"
}

if { ${family} == "kintex7" } {
   loadRuckusTcl "$::DIR_PATH/7Series"
}

if { ${family} == "virtex7" } {
   loadRuckusTcl "$::DIR_PATH/7Series"
}

if { ${family} == "zynq" } {
   loadRuckusTcl "$::DIR_PATH/7Series"
}

if { ${family} == "kintexu" } {
   loadRuckusTcl "$::DIR_PATH/UltraScale"
}
