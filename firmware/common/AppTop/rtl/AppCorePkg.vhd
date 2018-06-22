-------------------------------------------------------------------------------
--File       : AppCorePkg.vhd
--Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
--Description:
-------------------------------------------------------------------------------
--This file is part of 'DevBoard Common Platform'.
--It is subject to the license terms in the LICENSE.txt file found in the
--top-level directory of this distribution and at:
--https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
--No part of 'DevBoard Common Platform', including this file,
--may be copied, modified, propagated, or distributed except according to
--the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.SsiPkg.all;
use work.AxiStreamPkg.all;
use work.Jesd204bPkg.all;

package AppCorePkg is

   -- indices of AppCore's streaming port

   constant APP_DEBUG_STRM_C : natural := 0;
   constant APP_BPCLT_STRM_C : natural := 1;

   type AppCoreConfigType is record
      useTimingGth         : boolean;                   -- whether to use a GTH for timing (in-logic loopback otherwise)
      useXvcJtagBridge     : boolean;                   -- whether to use an XVC debug bridge
      appStreamConfig      : AxiStreamConfigType;
      macAddress           : slv(47 downto 0);
      ipAddress            : slv(31 downto 0);
      useDhcp              : boolean;
      enableEthJumboFrames : boolean;
      disableBSA           : boolean;
      disableBLD           : boolean;
      numAppLEDs           : natural;
      jesdClk_IDIV         : positive;
      jesdClk_MULT_F       : real;
      jesdClk_ODIV         : positive;
      jesdUsrClk_ODIV      : positive;
      numBays              : positive range 1 to 2;     -- how many DaqMuxes/SigGens to instantiate
      numSigGenerators     : NaturalArray (1 downto 0); -- 0 = disabled
      sigGenAddrWidth      : PositiveArray(1 downto 0);
      sigGenLaneMode       : Slv7Array    (1 downto 0); -- 0: 32-bit, 1: 16-bit
      sigGenRamClk         : Slv7Array    (1 downto 0); -- 0: jesd2x, 1: jesd1x
   end record;

   constant APP_CORE_CONFIG_DFLT_C : AppCoreConfigType := (
      useTimingGth         => true,
      useXvcJtagBridge     => true,
      appStreamConfig      => ssiAxiStreamConfig(8),
      macAddress           => x"010300564400",  -- 00:44:56:00:03:01 (ETH only)
      ipAddress            => x"0A02A8C0",      -- 192.168.2.10 (ETH only)
      useDhcp              => true,
      enableEthJumboFrames => false,
      disableBSA           => false,
      disableBLD           => false,
      numAppLEDs           => 4,
      jesdClk_IDIV         => 5,                -- with AXIL_CLK_FRQ_G = 125*5/4 -> 125/4MHz
      jesdClk_MULT_F       => 35.5,             -- 1109.375MHz
      jesdClk_ODIV         => 3,                -- 369.79MHz; divider for jesdClk2x
      jesdUsrClk_ODIV      => 9,                -- jesd2x / 3
      numBays              => 1,
      numSigGenerators     => (others => 4),         -- 0 = disabled
      sigGenAddrWidth      => (others => 9),
      sigGenLaneMode       => (others => "0000000"), -- 0: 32-bit, 1: 16-bit
      sigGenRamClk         => (others => "0000000")  -- 0: jesd2x, 1: jesd1x
   );

end package AppCorePkg;
