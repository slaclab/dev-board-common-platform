##############################################################################
## This file is part of 'Example Project Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'Example Project Firmware', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################
# I/O Port Mapping

# set_property -dict { PACKAGE_PIN V12 IOSTANDARD ANALOG } [get_ports { vPIn }]
# set_property -dict { PACKAGE_PIN W11 IOSTANDARD ANALOG } [get_ports { vNIn }]

set_property -dict { PACKAGE_PIN AN8 IOSTANDARD LVCMOS18 } [get_ports { extRst }]

set_property -dict { PACKAGE_PIN AP8 IOSTANDARD LVCMOS18 } [get_ports { led[0] }]
set_property -dict { PACKAGE_PIN H23 IOSTANDARD LVCMOS18 } [get_ports { led[1] }]
set_property -dict { PACKAGE_PIN P20 IOSTANDARD LVCMOS18 } [get_ports { led[2] }]
set_property -dict { PACKAGE_PIN P21 IOSTANDARD LVCMOS18 } [get_ports { led[3] }]
set_property -dict { PACKAGE_PIN N22 IOSTANDARD LVCMOS18 } [get_ports { led[4] }]
set_property -dict { PACKAGE_PIN M22 IOSTANDARD LVCMOS18 } [get_ports { led[5] }]
set_property -dict { PACKAGE_PIN R23 IOSTANDARD LVCMOS18 } [get_ports { led[6] }]
set_property -dict { PACKAGE_PIN P23 IOSTANDARD LVCMOS18 } [get_ports { led[7] }]

set_property PACKAGE_PIN U4 [get_ports ethTxP]
set_property PACKAGE_PIN U3 [get_ports ethTxN]
set_property PACKAGE_PIN T2 [get_ports ethRxP]
set_property PACKAGE_PIN T1 [get_ports ethRxN]

set_property PACKAGE_PIN P6 [get_ports ethClkP]
set_property PACKAGE_PIN P5 [get_ports ethClkN]

# Timing Constraints 
create_clock -name gtClkP -period 6.400    [get_ports {ethClkP}]
create_generated_clock -name ethClk125MHz  [get_pins {U_1GigE/U_MMCM/MmcmGen.U_Mmcm/CLKOUT0}] 
create_generated_clock -name ethClk62p5MHz [get_pins {U_1GigE/U_MMCM/MmcmGen.U_Mmcm/CLKOUT1}] 
create_generated_clock -name dnaClk        [get_pins {U_App/U_Reg/U_AxiVersion/GEN_DEVICE_DNA.DeviceDna_1/GEN_ULTRA_SCALE.DeviceDnaUltraScale_Inst/BUFGCE_DIV_Inst/O}]

set_clock_groups -asynchronous -group [get_clocks {gtClkP}] -group [get_clocks {ethClk125MHz}] 
set_clock_groups -asynchronous -group [get_clocks {gtClkP}] -group [get_clocks {ethClk62p5MHz}] 

set_clock_groups -asynchronous -group [get_clocks {ethClk125MHz}] -group [get_clocks {dnaClk}] 
 
# StdLib
set_property ASYNC_REG TRUE [get_cells -hierarchical *crossDomainSyncReg_reg*]
