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
#

set_property -dict { PACKAGE_PIN V12 IOSTANDARD ANALOG } [get_ports { vPIn }]
set_property -dict { PACKAGE_PIN W11 IOSTANDARD ANALOG } [get_ports { vNIn }]
set_property -dict { PACKAGE_PIN V13 IOSTANDARD ANALOG } [get_ports { v0PIn }]
set_property -dict { PACKAGE_PIN E13 IOSTANDARD ANALOG } [get_ports { v0NIn }]
set_property -dict { PACKAGE_PIN J13 IOSTANDARD ANALOG } [get_ports { v2PIn }]
set_property -dict { PACKAGE_PIN H13 IOSTANDARD ANALOG } [get_ports { v2NIn }]
set_property -dict { PACKAGE_PIN C11 IOSTANDARD ANALOG } [get_ports { v8PIn }]
set_property -dict { PACKAGE_PIN B11 IOSTANDARD ANALOG } [get_ports { v8NIn }]

set_property -dict { PACKAGE_PIN T27 IOSTANDARD LVCMOS18 } [get_ports { muxAddrOut[0] }]
set_property -dict { PACKAGE_PIN R27 IOSTANDARD LVCMOS18 } [get_ports { muxAddrOut[1] }]
set_property -dict { PACKAGE_PIN N27 IOSTANDARD LVCMOS18 } [get_ports { muxAddrOut[2] }]

set_property -dict { PACKAGE_PIN AJ9 IOSTANDARD LVCMOS18 } [get_ports { fanPwmOut }]

set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]

set_property -dict { PACKAGE_PIN AN8 IOSTANDARD LVCMOS18 } [get_ports { extRst }]

set_property -dict { PACKAGE_PIN AP8 IOSTANDARD LVCMOS18 } [get_ports { led[0] }]
set_property -dict { PACKAGE_PIN H23 IOSTANDARD LVCMOS18 } [get_ports { led[1] }]
set_property -dict { PACKAGE_PIN P20 IOSTANDARD LVCMOS18 } [get_ports { led[2] }]
set_property -dict { PACKAGE_PIN P21 IOSTANDARD LVCMOS18 } [get_ports { led[3] }]
set_property -dict { PACKAGE_PIN N22 IOSTANDARD LVCMOS18 } [get_ports { led[4] }]
set_property -dict { PACKAGE_PIN M22 IOSTANDARD LVCMOS18 } [get_ports { led[5] }]
set_property -dict { PACKAGE_PIN R23 IOSTANDARD LVCMOS18 } [get_ports { led[6] }]
set_property -dict { PACKAGE_PIN P23 IOSTANDARD LVCMOS18 } [get_ports { led[7] }]

# MDIO/Ext. PHY
set_property PACKAGE_PIN K25     [get_ports "phyIrqN"]
set_property IOSTANDARD LVCMOS18 [get_ports "phyIrqN"]
set_property PACKAGE_PIN L25     [get_ports "phyMdc"]
set_property IOSTANDARD LVCMOS18 [get_ports "phyMdc"]
set_property PACKAGE_PIN H26     [get_ports "phyMdio"]
set_property IOSTANDARD LVCMOS18 [get_ports "phyMdio"]
set_property PACKAGE_PIN J23     [get_ports "phyRstN"]
set_property IOSTANDARD LVCMOS18 [get_ports "phyRstN"]

# GPIO DIP Switch
set_property PACKAGE_PIN AN16 [get_ports "gpioDip[0]"]
set_property IOSTANDARD LVCMOS12 [get_ports "gpioDip[0]"]
set_property PACKAGE_PIN AN19 [get_ports "gpioDip[1]"]
set_property IOSTANDARD LVCMOS12 [get_ports "gpioDip[1]"]
set_property PACKAGE_PIN AP18 [get_ports "gpioDip[2]"]
set_property IOSTANDARD LVCMOS12 [get_ports "gpioDip[2]"]
set_property PACKAGE_PIN AN14 [get_ports "gpioDip[3]"]
set_property IOSTANDARD LVCMOS12 [get_ports "gpioDip[3]"]

# On-Board System clock
set_property ODT RTT_48 [get_ports "sysClk300N"]
set_property PACKAGE_PIN AK16 [get_ports "sysClk300N"]
set_property IOSTANDARD DIFF_SSTL12_DCI [get_ports "sysClk300N"]
set_property PACKAGE_PIN AK17 [get_ports "sysClk300P"]
set_property IOSTANDARD DIFF_SSTL12_DCI [get_ports "sysClk300P"]
set_property ODT RTT_48 [get_ports "sysClk300P"]

# GTH/SFP
set_property PACKAGE_PIN U4 [get_ports ethTxP]
set_property PACKAGE_PIN U3 [get_ports ethTxN]
set_property PACKAGE_PIN T2 [get_ports ethRxP]
set_property PACKAGE_PIN T1 [get_ports ethRxN]

set_property PACKAGE_PIN P6 [get_ports ethClkP]
set_property PACKAGE_PIN P5 [get_ports ethClkN]

# SGMII/Ext. PHY
set_property PACKAGE_PIN P25 [get_ports sgmiiRxN]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports sgmiiRxN]
set_property PACKAGE_PIN P24 [get_ports sgmiiRxP]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports sgmiiRxP]
set_property PACKAGE_PIN M24 [get_ports sgmiiTxN]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports sgmiiTxN]
set_property PACKAGE_PIN N24 [get_ports sgmiiTxP]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports sgmiiTxP]
set_property PACKAGE_PIN N26 [get_ports sgmiiClkN]
set_property IOSTANDARD LVDS_25 [get_ports sgmiiClkN]
set_property PACKAGE_PIN P26 [get_ports sgmiiClkP]
set_property IOSTANDARD LVDS_25 [get_ports sgmiiClkP]

# Placement - put SGMII ETH close in clock region of the 625MHz clock;
#             otherwise it is difficult to meet timing.
create_pblock SGMII_ETH_BLK
add_cells_to_pblock [get_pblocks SGMII_ETH_BLK] [get_cells U_1GigE_SGMII]
resize_pblock       [get_pblocks SGMII_ETH_BLK] -add {CLOCKREGION_X2Y1:CLOCKREGION_X2Y1}



# Timing Constraints 
create_clock -name sysClk300P  -period 3.333 [get_ports {sysClk300P}]
create_clock -name lcls1RefClk -period 4.202 [get_ports {ethClkP}  ]
create_clock -name lcls2RefClk -period 2.692 -add [get_ports {ethClkP}  ]

create_clock -name sgmiiClkP   -period 1.600 [get_ports {sgmiiClkP} ]

create_generated_clock -name sysClk156MHz [get_pins {U_SysPll/MmcmGen.U_Mmcm/CLKOUT0}]

create_generated_clock -name sgmiiClk125MHz  [get_pins {U_1GigE_SGMII/U_MMCM/CLKOUT0}] 

create_generated_clock -name dnaClk [get_pins {U_App/U_Reg/U_AxiVersion/GEN_DEVICE_DNA.DeviceDna_1/GEN_ULTRA_SCALE.DeviceDnaUltraScale_Inst/BUFGCE_DIV_Inst/O}]

create_generated_clock -name jesdClk2x  [get_pins {U_App/U_SimJesdClock/U_ClockGen/MmcmGen.U_Mmcm/CLKOUT0}]
create_generated_clock -name jesdClk    [get_pins {U_App/U_SimJesdClock/U_ClockGen/MmcmGen.U_Mmcm/CLKOUT1}]
create_generated_clock -name jesdUsrClk [get_pins {U_App/U_SimJesdClock/U_ClockGen/MmcmGen.U_Mmcm/CLKOUT2}]

set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets U_SysPll/CLKIN1]
