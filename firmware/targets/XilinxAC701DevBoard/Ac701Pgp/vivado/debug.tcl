##############################################################################
## This file is part of 'LCLS Laserlocker Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS Laserlocker Firmware', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

##############################
# Get variables and procedures
##############################
source -quiet $::env(RUCKUS_DIR)/vivado_env_var.tcl
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

############################
## Open the synthesis design
############################
open_run synth_1

###############################
## Set the name of the ILA core
###############################
set ilaName u_ila_0

##################
## Create the core
##################
CreateDebugCore ${ilaName}

#######################
## Set the record depth
#######################
set_property C_DATA_DEPTH 8192 [get_debug_cores ${ilaName}]

#################################
## Set the clock for the ILA core
#################################
SetDebugCoreClk ${ilaName} {clk}
#SetDebugCoreClk ${ilaName} {Core_Inst/CommonCore_Inst/ADC0_Inst/adcClk}

#######################
## Set the debug Probes
#######################

#ConfigProbe ${ilaName} {[*]}
#ConfigProbe ${ilaName} {u_Filter/AdcDataIn[*]}
#ConfigProbe ${ilaName} {u_Filter/Dec5}
#ConfigProbe ${ilaName} {u_Filter/iDataOut[*]}
#ConfigProbe ${ilaName} {u_Filter/Accumulator[*]}
#ConfigProbe ${ilaName} {u_Filter/AccumulatorM1[*]}
#ConfigProbe ${ilaName} {u_Filter/DecimationOut[*]}
#ConfigProbe ${ilaName} {u_Filter/iBoxCarDataOut[*]}
#ConfigProbe ${ilaName} {u_Filter/DACOut[*]}
#ConfigProbe ${ilaName} {u_Filter/iDACOut[*]}
#ConfigProbe ${ilaName} {u_Filter/iMult[*]}



##########################
## Write the port map file
##########################
WriteDebugProbes ${ilaName} ${PROJ_DIR}/images/debug_probes_${PRJ_VERSION}.ltx
