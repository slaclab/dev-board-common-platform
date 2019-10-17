# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Check for version 2016.4 of Vivado
if { [VersionCheck 2016.4] < 0 } {
   close_project
   exit -1
}

# Load ruckus files
loadRuckusTcl "$::DIR_PATH/submodules/amc-carrier-core/DaqMuxV2"
loadRuckusTcl "$::DIR_PATH/submodules/amc-carrier-core/DacSigGen"
loadRuckusTcl "$::DIR_PATH/submodules/amc-carrier-core/BsaCore"
# Load the FpgaTypePkg.vhd
if { $::env(PRJ_PART) == "XCKU040-FFVA1156-2-E" } {
   loadSource -path "$::DIR_PATH/submodules/amc-carrier-core/AmcCarrierCore/core/FpgaType/FpgaTypePkg_XCKU040.vhd"
} elseif { $::env(PRJ_PART) eq {XCKU060-FFVA1156-2-E} } {
   loadSource -path "$::DIR_PATH/submodules/amc-carrier-core/AmcCarrierCore/core/FpgaType/FpgaTypePkg_XCKU060.vhd"
} elseif { $::env(PRJ_PART) eq {XCKU095-FFVA1156-2-E} } {
   loadSource -path "$::DIR_PATH/submodules/amc-carrier-core/AmcCarrierCore/core/FpgaType/FpgaTypePkg_XCKU095.vhd"
} elseif { $::env(PRJ_PART) eq {XCKU11P-FFVA1156-2-E} } {
   loadSource -path "$::DIR_PATH/submodules/amc-carrier-core/AmcCarrierCore/core/FpgaType/FpgaTypePkg_XCKU11P.vhd"
} elseif { $::env(PRJ_PART) eq {XCKU15P-FFVA1156-2-E} } {
   loadSource -path "$::DIR_PATH/submodules/amc-carrier-core/AmcCarrierCore/core/FpgaType/FpgaTypePkg_XCKU15P.vhd"
} else {
}

loadSource -path  "$::DIR_PATH/submodules/amc-carrier-core/AmcCarrierCore/core/AmcCarrierBsa.vhd"
loadSource -path  "$::DIR_PATH/submodules/amc-carrier-core/AmcCarrierCore/core/AmcCarrierPkg.vhd"
loadSource -path  "$::DIR_PATH/submodules/amc-carrier-core/AppTop/rtl/xcku040/AppTopPkg.vhd"
loadSource -path  "$::DIR_PATH/submodules/amc-carrier-core/AppTop/rtl/AppMsgOb.vhd"
loadRuckusTcl "$::DIR_PATH/submodules/surf"
loadRuckusTcl "$::DIR_PATH/submodules/lcls-timing-core"
loadRuckusTcl "$::DIR_PATH/submodules/dev-board-misc-utils"
loadRuckusTcl "$::DIR_PATH/common"
