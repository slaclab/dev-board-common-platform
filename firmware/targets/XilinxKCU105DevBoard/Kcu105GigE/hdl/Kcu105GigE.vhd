-------------------------------------------------------------------------------
-- File       : Kcu105GigE.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-04-08
-- Last update: 2017-02-16
-------------------------------------------------------------------------------
-- Description: Example using 1000BASE-SX Protocol
-------------------------------------------------------------------------------
-- This file is part of 'Example Project Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'Example Project Firmware', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.AxiLitePkg.all;
use work.EthMacPkg.all;

library unisim;
use unisim.vcomponents.all;

entity Kcu105GigE is
   generic (
      TPD_G         : time    := 1 ns;
      BUILD_INFO_G  : BuildInfoType;
      SIM_SPEEDUP_G : boolean := false;
      SIMULATION_G  : boolean := false);
   port (
      -- Misc. IOs
      extRst     : in  sl;
      led        : out slv(7 downto 0);
      gpioDip    : in  slv(3 downto 0);
      -- XADC Ports
      vPIn       : in  sl;
      vNIn       : in  sl;
      -- ETH GT Pins
      ethClkP    : in  sl;
      ethClkN    : in  sl;
      ethRxP     : in  sl;
      ethRxN     : in  sl;
      ethTxP     : out sl;
      ethTxN     : out sl;
      -- SGMII (ext. PHY) ETH
      sgmiiClkP  : in  sl;
      sgmiiClkN  : in  sl;
      sgmiiRxP   : in  sl;
      sgmiiRxN   : in  sl;
      sgmiiTxP   : out sl;
      sgmiiTxN   : out sl;
      -- ETH external PHY pins
      phyMdc     : out sl;
      phyMdio    : inout sl;
      phyRstN    : out sl; -- active low
      phyIrqN    : in  sl; -- active low
      -- 300Mhz System Clock
      sysClk300P : in sl;
      sysClk300N : in sl);
end Kcu105GigE;

architecture top_level of Kcu105GigE is

   constant AXIS_SIZE_C : positive         := 1;
   constant IP_ADDR_C   : slv(31 downto 0) := x"0A02A8C0";          -- 192.168.2.10  
   constant MAC_ADDR_C  : slv(47 downto 0) := x"010300564400";      -- 00:44:56:00:03:01
   constant RST_DEL_C   : slv(22 downto 0) := toSlv(16#3FFFFF#,23); -- ~ 2*10ms @ 156MHz

   type MuxedSignalsType is record
      txMasters     : AxiStreamMasterArray(AXIS_SIZE_C-1 downto 0);
      txSlaves      : AxiStreamSlaveArray(AXIS_SIZE_C-1 downto 0);
      rxMasters     : AxiStreamMasterArray(AXIS_SIZE_C-1 downto 0);
      rxSlaves      : AxiStreamSlaveArray(AXIS_SIZE_C-1 downto 0);
      phyReady      : sl;
   end record;

   signal muxedSignals  : MuxedSignalsType;

   signal txMastersGTH  : AxiStreamMasterArray(AXIS_SIZE_C-1 downto 0);
   signal txSlavesGTH   : AxiStreamSlaveArray(AXIS_SIZE_C-1 downto 0);
   signal rxMastersGTH  : AxiStreamMasterArray(AXIS_SIZE_C-1 downto 0);
   signal rxSlavesGTH   : AxiStreamSlaveArray(AXIS_SIZE_C-1 downto 0);
   signal txMastersSGMII: AxiStreamMasterArray(AXIS_SIZE_C-1 downto 0);
   signal txSlavesSGMII : AxiStreamSlaveArray(AXIS_SIZE_C-1 downto 0);
   signal rxMastersSGMII: AxiStreamMasterArray(AXIS_SIZE_C-1 downto 0);
   signal rxSlavesSGMII : AxiStreamSlaveArray(AXIS_SIZE_C-1 downto 0);



   signal sgmiiClk      : sl;
   signal sgmiiRst      : sl;
   signal gthRstExt     : sl;
   signal sgmiiRstExt   : sl;

   signal sgmiiPhyReady : sl;
   signal gthPhyReady   : sl;

   signal selSGMII      : sl;

   signal gthDmaRst     : sl;
   signal sgmiiDmaRst   : sl;

   signal phyMdo        : sl := '1';

   signal sysClk300NB   : sl;
   signal sysClk156     : sl;
   signal sysRst156     : sl;
   signal sysMmcmLocked : sl;

   signal speed10_100   : sl := '0';
   signal speed100      : sl := '0';
   signal linkIsUp      : sl := '0';

   signal extPhyRstN    : sl;
   signal extPhyReady   : sl;
   signal rstCnt        : slv(22 downto 0) := RST_DEL_C;
   signal phyInitRst    : sl;
   signal phyIrq        : sl;
   signal phyMdi        : sl;


   signal initDone      : sl := '0';


   attribute dont_touch                 : string;
   attribute dont_touch of muxedSignals : signal is "TRUE";

   component Ila_256 is
      port (
         clk            : in  sl;
--       trig_out       : out sl;
--       trig_out_ack   : in  sl;
--       trig_in        : in  sl;
--       trig_in_ack    : out sl;
         probe0         : in  slv(255 downto 0)
      );
   end component ila_0;

begin

   -- hold unused ethernet in reset so it doesn't ARP or 
   -- communicate otherwise
   gthRstExt   <= extRst or selSGMII;
   sgmiiRstExt <= extRst or not selSGMII;

   gthDmaRst   <= sysRst156 or selSGMII;
   sgmiiDmaRst <= sysRst156 or not selSGMII;

   -- 300MHz system clock
   U_SysClk300IBUFDS : IBUFDS
      generic map (
         DIFF_TERM    => FALSE,
         IBUF_LOW_PWR => FALSE
      )
      port map (
         I            => sysClk300P,
         IB           => sysClk300N,
         O            => sysClk300NB
      );

   U_SysPll : entity work.ClockManagerUltrascale
      generic map (
         TPD_G            => TPD_G,
         INPUT_BUFG_G     => false,
         FB_BUFG_G        => false,
         NUM_CLOCKS_G     => 1,
         CLKIN_PERIOD_G   => 3.3333, -- 300MHz
         DIVCLK_DIVIDE_G  => 12,     -- VCO_in   25MHz
         CLKFBOUT_MULT_G  => 25,     -- VCO_out 625MHz
         CLKOUT0_DIVIDE_G => 4       -- Out0: 156.25MHz
      )
      port map (
         clkIn            => sysClk300NB,
         rstIn            => extRst,

         clkOut(0)        => sysClk156,
       
         rstOut(0)        => sysRst156,

         locked           => sysMmcmLocked
      );

   ---------------------
   -- 1 GigE XAUI Module
   ---------------------

   U_1GigE_GTH : entity work.GigEthGthUltraScaleWrapper
      generic map (
         TPD_G              => TPD_G,
         -- DMA/MAC Configurations
         NUM_LANE_G         => 1,
         -- QUAD PLL Configurations
         USE_GTREFCLK_G     => false,
         CLKIN_PERIOD_G     => 6.4,     -- 156.25 MHz
         DIVCLK_DIVIDE_G    => 5,       -- 31.25 MHz = (156.25 MHz/5)
         CLKFBOUT_MULT_F_G  => 32.0,    -- 1 GHz = (32 x 31.25 MHz)
         CLKOUT0_DIVIDE_F_G => 8.0,     -- 125 MHz = (1.0 GHz/8)         
         -- AXI Streaming Configurations
         AXIS_CONFIG_G      => (others => EMAC_AXIS_CONFIG_C))
      port map (
         -- Local Configurations
         localMac     => (others => MAC_ADDR_C),
         -- Streaming DMA Interface 
         dmaClk       => (others => sysClk156),
         dmaRst       => (others => gthDmaRst),
         dmaIbMasters => rxMastersGTH,
         dmaIbSlaves  => rxSlavesGTH,
         dmaObMasters => txMastersGTH,
         dmaObSlaves  => txSlavesGTH,
         -- Misc. Signals
         extRst       => gthRstExt,
         phyClk       => open,
         phyRst       => open,
         phyReady(0)  => gthPhyReady,
         -- MGT Clock Port
         gtClkP       => ethClkP,
         gtClkN       => ethClkN,
         -- MGT Ports
         gtTxP(0)     => ethTxP,
         gtTxN(0)     => ethTxN,
         gtRxP(0)     => ethRxP,
         gtRxN(0)     => ethRxN);

   -- Main clock is derived from the PHY refclock. However,
   -- while it is in reset there is no clock coming in;
   -- thus we use the on-board clock to reset the (external) PHY.
   -- We must hold reset for >10ms and then wait >5ms until we may talk
   -- to it (we actually wait also >10ms) which is indicated by 'extPhyReady'.
   process (sysClk156)
   begin
      if ( rising_edge( sysClk156 ) ) then
         if ( sysRst156 /= '0' ) then
            rstCnt <= RST_DEL_C;
         elsif ( rstCnt(22) = '0' ) then
            rstCnt <= slv( unsigned( rstCnt ) - 1 );
         end if;
      end if;
   end process;

   extPhyReady <= rstCnt(22);

   extPhyRstN  <= ite( ( unsigned(rstCnt(21 downto 20)) >= 2 ) and ( extPhyReady = '0' ), '0', '1' );

   -- The MDIO controller which talks to the external PHY must be held
   -- in reset until extPhyReady; it works in a different clock domain...

   U_PhyInitRstSync : entity work.RstSync
      generic map (
         IN_POLARITY_G  => '0',
         OUT_POLARITY_G => '1'
      )
      port map (
         clk            => sgmiiClk,
         asyncRst       => extPhyReady,
         syncRst        => phyInitRst
      );

   -- The SaltCore does not support autonegotiation on the SGMII link
   -- (mac<->phy) - however, the marvell phy (by default) assumes it does.
   -- We need to disable auto-negotiation in the PHY on the SGMII side
   -- and handle link changes (aneg still enabled on copper) flagged
   -- by the PHY...

   U_PhyCtrl : entity work.PhyControllerCore
      generic map (
         TPD_G    => TPD_G,
         DIV_G    => 100
      )
      port map (
         clk             => sgmiiClk,
         rst             => phyInitRst,
         initDone        => initDone,

         speed_is_10_100 => speed10_100,
         speed_is_100    => speed100,
         linkIsUp        => linkIsUp,

         mdi             => phyMdi,
         mdc             => phyMdc,
         mdo             => phyMdo,

         linkIrq         => phyIrq
      );

   -- synchronize MDI and IRQ signals into 'sgmiiClk' domain
   U_SyncMdi : entity work.Synchronizer
      port map (
         clk       => sgmiiClk,
         dataIn    => phyMdio,
         dataOut   => phyMdi
      );

   U_SyncIrq : entity work.Synchronizer
      generic map (
         OUT_POLARITY_G => '0',
         INIT_G         => "11"
      )
      port map (
         clk       => sgmiiClk,
         dataIn    => phyIrqN,
         dataOut   => phyIrq
      );

   U_1GigE_SGMII : entity work.GigEthLVDSUltraScaleWrapper
      generic map (
         TPD_G              => TPD_G,
         -- DMA/MAC Configurations
         NUM_LANE_G         => 1,
         -- MMCM Configuration
         USE_REFCLK_G       => false,
         CLKIN_PERIOD_G     => 1.6,     -- 625.0 MHz
         DIVCLK_DIVIDE_G    => 2,       -- 312.5 MHz
         CLKFBOUT_MULT_F_G  => 2.0,     -- VCO: 625 MHz
         -- AXI Streaming Configurations
         AXIS_CONFIG_G      => (others => EMAC_AXIS_CONFIG_C))
      port map (
         -- Local Configurations
         localMac           => (others => MAC_ADDR_C),
         -- Streaming DMA Interface 
         dmaClk             => (others => sysClk156),
         dmaRst             => (others => sgmiiDmaRst),
         dmaIbMasters       => rxMastersSGMII,
         dmaIbSlaves        => rxSlavesSGMII,
         dmaObMasters       => txMastersSGMII,
         dmaObSlaves        => txSlavesSGMII,
         -- Misc. Signals
         extRst             => sgmiiRstExt,
         phyClk             => sgmiiClk,
         phyRst             => sgmiiRst,
         phyReady(0)        => sgmiiPhyReady,
         mmcmLocked         => open,
         speed_is_10_100(0) => speed10_100,
         speed_is_100(0)    => speed100,

         -- MGT Clock Port
         sgmiiClkP          => sgmiiClkP,
         sgmiiClkN          => sgmiiClkN,
         -- MGT Ports
         sgmiiTxP(0)        => sgmiiTxP,
         sgmiiTxN(0)        => sgmiiTxN,
         sgmiiRxP(0)        => sgmiiRxP,
         sgmiiRxN(0)        => sgmiiRxN);

   txMastersGTH   <= muxedSignals.txMasters    when selSGMII = '0' else (others => AXI_STREAM_MASTER_INIT_C);
   rxSlavesGTH    <= muxedSignals.rxSlaves     when selSGMII = '0' else (others => AXI_STREAM_SLAVE_FORCE_C);
   txMastersSGMII <= muxedSignals.txMasters    when selSGMII = '1' else (others => AXI_STREAM_MASTER_INIT_C);
   rxSlavesSGMII  <= muxedSignals.rxSlaves     when selSGMII = '1' else (others => AXI_STREAM_SLAVE_FORCE_C);

   muxedSignals.txSlaves   <= txSlavesGTH  when selSGMII = '0' else txSlavesSGMII;
   muxedSignals.rxMasters  <= rxMastersGTH when selSGMII = '0' else rxMastersSGMII;

   muxedSignals.phyReady   <= gthPhyReady  when selSGMII = '0' else sgmiiPhyReady;

   -------------------
   -- Application Core
   -------------------
   U_App : entity work.AppCore
      generic map (
         TPD_G        => TPD_G,
         BUILD_INFO_G => BUILD_INFO_G,
         XIL_DEVICE_G => "ULTRASCALE",
         APP_TYPE_G   => "ETH",
         AXIS_SIZE_G  => AXIS_SIZE_C,
         MAC_ADDR_G   => MAC_ADDR_C,
         IP_ADDR_G    => IP_ADDR_C)
      port map (
         -- Clock and Reset
         clk       => sysClk156,
         rst       => sysRst156,
         -- AXIS interface
         txMasters => muxedSignals.txMasters,
         txSlaves  => muxedSignals.txSlaves,
         rxMasters => muxedSignals.rxMasters,
         rxSlaves  => muxedSignals.rxSlaves,
         -- ADC Ports
         vPIn      => vPIn,
         vNIn      => vNIn);

   ----------------
   -- Misc. Signals
   ----------------
   led(7) <= linkIsUp;
   led(6) <= not speed10_100;             -- lit when 1Gb
   led(5) <= not speed10_100 or speed100; -- lit when 1Gb or 100Mb
   led(4) <= extPhyRstN;
   led(3) <= phyIrqN;
   led(2) <= initDone;
   led(1) <= muxedSignals.phyReady;
   led(0) <= muxedSignals.phyReady;

   U_SyncSel : entity work.Synchronizer
      port map (
         clk     => sysClk156,
         dataIn  => gpioDip(0),
         dataOut => selSGMII
      );

   -- Tri-state driver for phyMdio
   phyMdio <= 'Z' when phyMdo = '1' else '0';
   -- Reset line of the external phy
   phyRstN <= extPhyRstN;

   U_ila     : component Ila_256
      port map (
         clk          => sysClk156,
--       trig_out_ack => '1',
--       trig_in      => '0',
         probe0(0)    => muxedSignals.txMasters(0).tValid ,
         probe0(1)    => muxedSignals.txSlaves(0).tReady  ,
         probe0(2)    => muxedSignals.txMasters(0).tLast  ,
         probe0(3)    => muxedSignals.rxMasters(0).tValid ,
         probe0(4)    => muxedSignals.rxSlaves(0).tReady  ,
         probe0(5)    => muxedSignals.rxMasters(0).tLast  ,
         probe0(255 downto 6) => (others => '0')
      );

end top_level;
