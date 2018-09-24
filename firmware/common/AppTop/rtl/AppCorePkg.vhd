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

   type IOLine is record
      o : sl; -- driven by IOBUF
      i : sl; -- driven by signal
      t : sl; -- 1 for input; 0 for output
   end record;

   constant IOLINE_DEFAULT_C : IOLine := (
      o => 'Z',
      i => '0',
      t => '1'
   );

   type IOLine8Array is array(7 downto 0) of IOLine;

   type PMODArray is array (natural range <>) of IOLine8Array;

   type AppCoreConfigType is record
      useTimingGth         : boolean;                   -- whether to use a GTH for timing (in-logic loopback otherwise)
      useXvcJtagBridge     : boolean;                   -- whether to use an XVC debug bridge
      appStreamConfig      : AxiStreamConfigType;
      macAddress           : slv(47 downto 0);
      ipAddress            : slv(31 downto 0);
      useDhcp              : boolean;
      enableEthJumboFrames : boolean;
      -- NOTE: When disabling interleaved RSSI the top-level YAML
      --       MUST be changed accordingly:
      --       Interleaved RSSI:
      ---        UDP/port: 8198
      ---        depack/protocolVersion: DEPACKETIZER_V2
      --       Non-interleaved RSSI:
      ---        UDP/port: 8193
      ---        depack/protocolVersion: DEPACKETIZER_V0
      enableRssiInterleave : boolean; -- whether to enable interleaved RSSI
      enableSRPV0          : boolean; -- whether to instantiate V0 backdoor
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
      smaPTrigger          : integer; -- which trigger to connect to GPIO SMA P (-1 for none)
      smaNTrigger          : integer; -- which trigger to connect to GPIO SMA P (-1 for none)
      waveformTdataBytes   : positive range 4 to 8; -- AXI stream width between DaqMuxV2 and BSA
   end record;

   constant APP_CORE_CONFIG_DFLT_C : AppCoreConfigType := (
      useTimingGth         => true,
      useXvcJtagBridge     => true,
      appStreamConfig      => ssiAxiStreamConfig(8),
      macAddress           => x"010300564400",  -- 00:44:56:00:03:01 (ETH only)
      ipAddress            => x"0A02A8C0",      -- 192.168.2.10 (ETH only)
      useDhcp              => true,
      enableEthJumboFrames => true,
      -- NOTE: When disabling interleaved RSSI the top-level YAML
      --       MUST be changed accordingly:
      enableRssiInterleave => true,
      enableSRPV0          => true,
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
      sigGenRamClk         => (others => "0000000"), -- 0: jesd2x, 1: jesd1x
      smaPTrigger          => 8,
      smaNTrigger          => 9,
      waveformTdataBytes   => 4
   );

end package AppCorePkg;
