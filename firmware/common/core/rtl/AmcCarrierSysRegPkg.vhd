-------------------------------------------------------------------------------
-- File       : AmcCarrierSysRegPkg.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-08
-- Last update: 2017-04-26
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 Common Carrier Core'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'LCLS2 Common Carrier Core', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;

package AmcCarrierSysRegPkg is

   constant SYSREG_BASE_ADDR_C : slv(31 downto 0) := x"0000_0000";

   constant NUM_AXI_MASTERS_C : natural := 9;

   constant VERSION_INDEX_C : natural := 0;
   constant XADC_INDEX_C    : natural := 1;
   constant SYS_MON_INDEX_C : natural := 2;
   constant IIC_MAS_INDEX_C : natural := 3;
   constant TIMCORE_INDEX_C : natural := 4;
   constant TIM_GTH_INDEX_C : natural := 5;
   constant TIM_TRG_INDEX_C : natural := 6;
   constant TCLKSWI_INDEX_C : natural := 7;
   constant BSA_INDEX_C     : natural := 8;

   constant SYSREG_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) :=
      genAxiLiteConfig( NUM_AXI_MASTERS_C, SYSREG_BASE_ADDR_C, 28, 24 );

   ---------------------------------------------
   -- Register Mapping: 1st Layer base addresses
   ---------------------------------------------
   constant VERSION_ADDR_C    : slv(31 downto 0) := SYSREG_MASTERS_CONFIG_C(VERSION_INDEX_C).baseAddr;
   constant SYSMON_ADDR_C     : slv(31 downto 0) := SYSREG_MASTERS_CONFIG_C(SYS_MON_INDEX_C).baseAddr;
   constant TIMING_ADDR_C     : slv(31 downto 0) := SYSREG_MASTERS_CONFIG_C(TIMCORE_INDEX_C).baseAddr;
   constant BSA_ADDR_C        : slv(31 downto 0) := SYSREG_MASTERS_CONFIG_C(BSA_INDEX_C    ).baseAddr;

end package AmcCarrierSysRegPkg;
