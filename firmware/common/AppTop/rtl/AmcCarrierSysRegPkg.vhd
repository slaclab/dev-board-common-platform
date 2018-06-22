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


   constant VERSION_INDEX_C : natural := 0;
   constant XADC_INDEX_C    : natural := 1;
   constant SYS_MON_INDEX_C : natural := 2;
   constant IIC_MAS_INDEX_C : natural := 3;
   constant TIMCORE_INDEX_C : natural := 4;
   constant TIM_GTH_INDEX_C : natural := 5;
   constant TIM_TRG_INDEX_C : natural := 6;
   constant TCLKSWI_INDEX_C : natural := 7;
   constant BSA_INDEX_C     : natural := 8;
   constant ETH_INDEX_C     : natural := 9;
   constant FAN_INDEX_C     : natural :=10;
   constant APP_INDEX_C     : natural :=11;

   constant NUM_AXI_MASTERS_C : natural := 12;

   ---------------------------------------------
   -- Register Mapping: 1st Layer base addresses
   ---------------------------------------------
   constant VERSION_ADDR_C    : slv(31 downto 0) := x"0000_0000";
   constant XADC_ADDR_C       : slv(31 downto 0) := x"0100_0000";
   constant SYS_MON_ADDR_C    : slv(31 downto 0) := x"0200_0000";
   constant IIC_MAS_ADDR_C    : slv(31 downto 0) := x"0300_0000";
   constant TIMCORE_ADDR_C    : slv(31 downto 0) := x"0400_0000";
   constant TIM_GTH_ADDR_C    : slv(31 downto 0) := x"0500_0000";
   constant TIM_TRG_ADDR_C    : slv(31 downto 0) := x"0600_0000";
   constant TCLKSWI_ADDR_C    : slv(31 downto 0) := x"0700_0000";
   constant BSA_ADDR_C        : slv(31 downto 0) := x"0800_0000";
   constant ETH_ADDR_C        : slv(31 downto 0) := x"0900_0000";
   constant FAN_ADDR_C        : slv(31 downto 0) := x"0a00_0000";
   constant APP_ADDR_C        : slv(31 downto 0) := x"8000_0000";

   constant SYSREG_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) :=
      (
         VERSION_INDEX_C => (
            baseAddr         => VERSION_ADDR_C,
            addrBits         => 24,
            connectivity     => x"FFFF"
                            ),
         XADC_INDEX_C    => (
            baseAddr         => XADC_ADDR_C,
            addrBits         => 24,
            connectivity     => x"FFFF"
                            ),
         SYS_MON_INDEX_C => (
            baseAddr         => SYS_MON_ADDR_C,
            addrBits         => 24,
            connectivity     => x"FFFF"
                            ),
         IIC_MAS_INDEX_C => (
            baseAddr         => IIC_MAS_ADDR_C,
            addrBits         => 24,
            connectivity     => x"FFFF"
                            ),
         TIMCORE_INDEX_C => (
            baseAddr         => TIMCORE_ADDR_C,
            addrBits         => 24,
            connectivity     => x"FFFF"
                            ),
         TIM_GTH_INDEX_C => (
            baseAddr         => TIM_GTH_ADDR_C,
            addrBits         => 24,
            connectivity     => x"FFFF"
                            ),
         TIM_TRG_INDEX_C => (
            baseAddr         => TIM_TRG_ADDR_C,
            addrBits         => 24,
            connectivity     => x"FFFF"
                            ),
         TCLKSWI_INDEX_C => (
            baseAddr         => TCLKSWI_ADDR_C,
            addrBits         => 24,
            connectivity     => x"FFFF"
                            ),
         BSA_INDEX_C     => (
            baseAddr         => BSA_ADDR_C,
            addrBits         => 24,
            connectivity     => x"FFFF"
                            ),
         ETH_INDEX_C     => (
            baseAddr         => ETH_ADDR_C,
            addrBits         => 24,
            connectivity     => x"FFFF"
                            ),
         FAN_INDEX_C     => (
            baseAddr         => FAN_ADDR_C,
            addrBits         => 16,
            connectivity     => x"FFFF"
                            ),
         APP_INDEX_C     => (
            baseAddr         => APP_ADDR_C,
            addrBits         => 31,
            connectivity     => x"FFFF"
                            )
      );

end package AmcCarrierSysRegPkg;
