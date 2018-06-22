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
loadSource -path  "$::DIR_PATH/submodules/amc-carrier-core/AmcCarrierCore/dcp/hdl/AmcCarrierBsa.vhd"
loadSource -path  "$::DIR_PATH/submodules/amc-carrier-core/AmcCarrierCore/core/AmcCarrierPkg.vhd"
loadSource -path  "$::DIR_PATH/submodules/amc-carrier-core/AppTop/rtl/xcku040/AppTopPkg.vhd"
loadRuckusTcl "$::DIR_PATH/submodules/surf"
loadRuckusTcl "$::DIR_PATH/submodules/lcls-timing-core"
loadRuckusTcl "$::DIR_PATH/submodules/dev-board-misc-utils"
loadRuckusTcl "$::DIR_PATH/common"
