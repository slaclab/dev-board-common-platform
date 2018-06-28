-------------------------------------------------------------------------------
-- File       : Kcu105Eth.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-04-08
-- Last update: 2017-02-16
-------------------------------------------------------------------------------
-- Description: Example using 1000BASE-SX Protocol
-------------------------------------------------------------------------------
-- This file is part of 'DevBoard Common Platform'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'DevBoard Common Platform', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.AxiLitePkg.all;
use work.AxiPkg.all;
use work.EthMacPkg.all;
use work.SsiPkg.all;
use work.TimingPkg.all;
use work.AppCoreConfigPkg.all;
use work.AppCorePkg.all;

library unisim;
use unisim.vcomponents.all;

entity Kcu105Eth is
   generic (
      TPD_G              : time     := 1 ns;
      BUILD_INFO_G       : BuildInfoType;
      DISABLE_10G_ETH_G  : natural  := 0;
      SIM_SPEEDUP_G      : boolean  := false;
      SIMULATION_G       : boolean  := false
   );
   port (
      -- Misc. IOs
      extRst     : in  sl;
      led        : out slv(7 downto 0);
      gpioDip    : in  slv(3 downto 0);
      -- XADC Ports
      v0PIn      : in  sl;
      v0NIn      : in  sl;
      v2PIn      : in  sl;
      v2NIn      : in  sl;
      v8PIn      : in  sl;
      v8NIn      : in  sl;
      vPIn       : in  sl;
      vNIn       : in  sl;
      muxAddrOut : out slv(2 downto 0);
      -- Fan control
      fanPwmOut  : out sl;
      -- MGT refclk 1 : bank 227 (from Si5238)
      -- MGT refclk 0 : bank 227 (from Si570 or Si5328 out2 via mux)
      refClkP    : in  slv(1 downto 0);
      refClkN    : in  slv(1 downto 0);
      -- SFP[0] (P5 cage, closer to RJ45      ) Bank 226, GTH-2
      -- SFP[1] (P4 cage, closer to board edge) Bank 226, GTH-1
      sfpRxP     : in  slv(1 downto 0);
      sfpRxN     : in  slv(1 downto 0);
      sfpTxP     : out slv(1 downto 0);
      sfpTxN     : out slv(1 downto 0);
      -- Second SFP cage
      -- SGMII (ext. PHY) ETH
      sgmiiClkP  : in  sl;
      sgmiiClkN  : in  sl;
      sgmiiRxP   : in  sl;
      sgmiiRxN   : in  sl;
      sgmiiTxP   : out sl;
      sgmiiTxN   : out sl;
      -- Si5328 reset
      si5328RstN : out sl   := '1';
      si5328Int  : in  sl;
      -- ETH external PHY pins
      phyMdc     : out sl;
      phyMdio    : inout sl := 'Z';
      phyRstN    : out sl   := '1'; -- active low
      phyIrqN    : in  sl; -- active low
      -- 300Mhz System Clock
      sysClk300P : in sl;
      sysClk300N : in sl;
      -- DDR4 Ports
      c0_ddr4_adr : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
      c0_ddr4_dq : INOUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      c0_ddr4_dm_dbi_n : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      c0_ddr4_dqs_c : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      c0_ddr4_dqs_t : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      c0_ddr4_ba : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      c0_ddr4_bg : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      c0_ddr4_cke : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      c0_ddr4_cs_n : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      c0_ddr4_odt : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      c0_ddr4_reset_n : OUT STD_LOGIC;
      c0_ddr4_act_n : OUT STD_LOGIC;
      c0_ddr4_ck_c : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      c0_ddr4_ck_t : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      c0_ddr4_alert_n : IN STD_LOGIC;
      -- I2C Bus
      iicScl     : inout sl;
      iicSda     : inout sl;
      iicMuxRstN : out   sl := '1'; -- deassert IIC Mux reset
      -- SMA
      gpioSmaP   : inout sl;
      gpioSmaN   : inout sl;
      pmod       : inout Slv8Array(1 downto 0)
   );
end Kcu105Eth;

architecture top_level of Kcu105Eth is

   constant NUM_LANE_C         : natural := 1;
   constant NUM_APP_LEDS_C     : natural := APP_CORE_CONFIG_C.numAppLEDs;

   -- max. positive number; at RST_LEN_LD_C bits this is 2**RST_LEN_LD_C/sysClk256
   -- (01111111...)
   --
   --   1. reset is held asserted for half that time
   --   2. extPhyReady is asserted after the other half of that time expires
   --
   -- => for the PHY, 2*10ms, i.e., RST_LEN_LD_C == 22 would be sufficient
   --    at 156.25 MHz.
   --
   -- *** HOWEVER: I found that when I boot from the SD-card the system controller
   -- ***          does stuff on the I2C bus until ~15ms AFTER the FPGA is configured.
   -- ***          In particular, the I2C Mux is reset by the system controller.
   -- ***          (I monitored SCL and latched a running counter each time
   -- ***          a rising edge on SCL was detected).
   -- *** => We hold reset asserted for a longer time; make that ~50ms
   --
   constant RST_LEN_LD_C : natural := 24;

   subtype  ResetCountType is signed(RST_LEN_LD_C downto 0);

   constant RST_DEL_C : ResetCountType := (
      ResetCountType'left => '0',
      others              => '1'
   );

   constant AXIS_SIZE_C : positive           := 1;

   constant AXIL_CLK_FRQ_C : real := 156.25E6;

   -- Mem read word size is 32 bits
   constant MEM_AXI_CONFIG_C : AxiConfigType := (
      ADDR_WIDTH_C => 31,
      DATA_BYTES_C => 4,
      ID_BITS_C    => 4,
      LEN_BITS_C   => 8
   );

   type MuxedSignalsType is record
      txMasters     : AxiStreamMasterArray(NUM_LANE_C-1 downto 0);
      txSlaves      : AxiStreamSlaveArray(NUM_LANE_C-1 downto 0);
      rxMasters     : AxiStreamMasterArray(NUM_LANE_C-1 downto 0);
      rxSlaves      : AxiStreamSlaveArray(NUM_LANE_C-1 downto 0);
   end record;

   signal keptSignals   : MuxedSignalsType;

   signal txMastersSGMII: AxiStreamMasterArray(NUM_LANE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal txSlavesSGMII : AxiStreamSlaveArray (NUM_LANE_C-1 downto 0);
   signal rxMastersSGMII: AxiStreamMasterArray(NUM_LANE_C-1 downto 0);
   signal rxSlavesSGMII : AxiStreamSlaveArray (NUM_LANE_C-1 downto 0) := (others => AXI_STREAM_SLAVE_FORCE_C);

   signal txMastersGTH  : AxiStreamMasterArray(NUM_LANE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal txSlavesGTH   : AxiStreamSlaveArray (NUM_LANE_C-1 downto 0);
   signal rxMastersGTH  : AxiStreamMasterArray(NUM_LANE_C-1 downto 0);
   signal rxSlavesGTH   : AxiStreamSlaveArray (NUM_LANE_C-1 downto 0) := (others => AXI_STREAM_SLAVE_FORCE_C);


   signal axiClk        : sl;
   signal axiRst        : sl;

   signal sysClk300NB   : sl;
   signal ddrClk300     : sl;
   signal sysClk156     : sl;
   signal sysRst156     : sl;
   signal sysRst156_i   : sl;
   signal sysMmcmLocked : sl;

   signal rstCnt        : ResetCountType := RST_DEL_C;

   signal memReady      : sl;

   signal memAxiWriteMaster    : AxiWriteMasterType;
   signal memAxiWriteSlave     : AxiWriteSlaveType;
   signal memAxiReadMaster     : AxiReadMasterType;
   signal memAxiReadSlave      : AxiReadSlaveType;

   signal appTimingClk  : sl;
   signal appTimingRst  : sl;

   signal dmaClk        : slv(NUM_LANE_C-1 downto 0);
   signal dmaRst        : slv(NUM_LANE_C-1 downto 0);

   signal appLeds       : slv(NUM_APP_LEDS_C - 1 downto 0);
   signal muxAddrLoc    : slv(4            downto 0);

   signal gpioSmaPBuf   : IOLine;
   signal gpioSmaNBuf   : IOLine;
   signal pmodBuf       : PMODArray(1 downto 0);

   signal speed10_100   : sl := '0';
   signal speed100      : sl := '0';
   signal linkIsUp      : sl := '0';

   signal extPhyRstN    : sl;
   signal extPhyReady   : sl;
   signal phyInitRst    : sl;
   signal phyIrq        : sl;
   signal phyMdi        : sl;

   signal sgmiiClk      : sl;
   signal sgmiiRst      : sl;

   signal phyMdo        : sl := '1';

   signal initDone      : sl := '0';

   signal ethMuxGTH     : sl := '0';

   signal localMac      : slv(47 downto 0) := APP_CORE_CONFIG_C.macAddress;
   signal localIp       : slv(31 downto 0) := APP_CORE_CONFIG_C.ipAddress;

   signal localMacArray : Slv48Array(NUM_LANE_C - 1 downto 0);

   attribute dont_touch                 : string;
   attribute dont_touch of keptSignals  : signal is "TRUE";
   attribute dont_touch of ddrClk300    : signal is "TRUE";

   component Ila_256 is
      port (
         clk            : in  sl;
--       trig_out       : out sl;
--       trig_out_ack   : in  sl;
--       trig_in        : in  sl;
--       trig_in_ack    : out sl;
         probe0         : in  slv(63 downto 0) := (others => '0');
         probe1         : in  slv(63 downto 0) := (others => '0');
         probe2         : in  slv(63 downto 0) := (others => '0');
         probe3         : in  slv(63 downto 0) := (others => '0')
      );
   end component Ila_256;

begin

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

   U_Sysclk300 : BUFG
      port map (
         I            => sysClk300NB,
         O            => ddrClk300
      );

   U_SysPll : entity work.ClockManagerUltrascale
      generic map (
         TPD_G            => TPD_G,
         INPUT_BUFG_G     => true,
         FB_BUFG_G        => true,
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

         rstOut(0)        => sysRst156_i,

         locked           => sysMmcmLocked
      );

   -- Main clock is derived from the PHY refclock. However,
   -- while it is in reset there is no clock coming in;
   -- thus we use the on-board clock to reset the (external) PHY.
   -- We must hold reset for >10ms and then wait >5ms until we may talk
   -- to it (we actually wait also >10ms) which is indicated by 'extPhyReady'.
   -- Note: the actual reset period might be longer due to other needs but
   --       the general scheme is
   --       1. hold sysRst156 asserted for period X (>10ms)
   --       2. deassert sysRst156
   --       3. wait for period X (>10ms)
   --       4. assert extPhyReady
   process (sysClk156)
   begin
      if ( rising_edge( sysClk156 ) ) then
         if ( sysRst156_i /= '0' ) then
            rstCnt <= RST_DEL_C;
         elsif ( rstCnt >= 0 ) then
            rstCnt <= rstCnt - 1;
         end if;
      end if;
   end process;

   extPhyReady <= ite(rstCnt < 0, '1', '0');

   sysRst156   <= ite(rstCnt(rstCnt'left downto rstCnt'left - 2) >= 2, '1', '0');

   extPhyRstN  <= not sysRst156;

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

   dmaClk <= (others => sysClk156);
   dmaRst <= (others => sysRst156);

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
         AXIS_CONFIG_G      => (others => EMAC_AXIS_CONFIG_C)
      )
      port map (
         -- Local Configurations
         localMac           => localMacArray,
         -- Streaming DMA Interface
         dmaClk             => dmaClk,
         dmaRst             => dmaRst,
         dmaIbMasters       => rxMastersSGMII,
         dmaIbSlaves        => rxSlavesSGMII,
         dmaObMasters       => txMastersSGMII,
         dmaObSlaves        => txSlavesSGMII,
         -- Misc. Signals
         extRst             => extRst,
         phyClk             => sgmiiClk,
         phyRst             => sgmiiRst,
         phyReady           => open,
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
         sgmiiRxN(0)        => sgmiiRxN
      );

   GEN_10G_GTH : if ( DISABLE_10G_ETH_G = 0 ) generate
      signal clk      : sl;
      signal rst      : sl;
      signal phyReady : sl;
   begin
   -----------------
   -- 10 GigE Module
   -----------------

   U_10GigE : entity work.TenGigEthGthUltraScaleWrapper
      generic map (
         TPD_G             => TPD_G,
         NUM_LANE_G        => 1,
         -- QUAD PLL Configurations
         QPLL_REFCLK_SEL_G => "001",
         -- AXI Streaming Configurations
         AXIS_CONFIG_G     => (others => EMAC_AXIS_CONFIG_C))
      port map (
         -- Local Configurations
         localMac          => localMacArray,

         -- Streaming DMA Interface
         dmaClk       => dmaClk,
         dmaRst       => dmaRst,
         dmaIbMasters => rxMastersGTH,
         dmaIbSlaves  => rxSlavesGTH,
         dmaObMasters => txMastersGTH,
         dmaObSlaves  => txSlavesGTH,
         -- Misc. Signals
         extRst       => extRst,
         coreClk      => clk, -- out
         coreRst      => rst, -- out

         phyReady(0)  => phyReady,
         -- MGT Clock Port (156.25 MHz or 312.5 MHz)
         gtClkP       => refClkP(0),
         gtClkN       => refClkN(0),
         -- MGT Ports
         gtTxP(0)     => sfpTxP(0),
         gtTxN(0)     => sfpTxN(0),
         gtRxP(0)     => sfpRxP(0),
         gtRxN(0)     => sfpRxN(0)
      );

   -- latch state of dip-switch during reset
   P_ETH_MUX_SWITCH : process ( sysClk156 )
   begin
      if ( rising_edge( sysClk156 ) ) then
         if ( sysRst156 = '1' ) then
            ethMuxGTH <= gpioDip(3);
         end if;
      end if;
   end process P_ETH_MUX_SWITCH;

   end generate;

   P_ETH_MUX : process( ethMuxGTH, keptSignals, txSlavesGTH, txSlavesSGMII, rxMastersGTH, rxMastersSGMII )
   begin
      if ( ethMuxGTH = '1' ) then
         txMastersGTH          <= keptSignals.txMasters;
         keptSignals.txSlaves  <= txSlavesGTH;
         rxSlavesGTH           <= keptSignals.rxSlaves;
         keptSignals.rxMasters <= rxMastersGTH;
         txMastersSGMII        <= (others => AXI_STREAM_MASTER_INIT_C);
         rxSlavesSGMII         <= (others => AXI_STREAM_SLAVE_FORCE_C);
      else
         txMastersSGMII        <= keptSignals.txMasters;
         keptSignals.txSlaves  <= txSlavesSGMII;
         rxSlavesSGMII         <= keptSignals.rxSlaves;
         keptSignals.rxMasters <= rxMastersSGMII;
         txMastersGTH          <= (others => AXI_STREAM_MASTER_INIT_C);
         rxSlavesGTH           <= (others => AXI_STREAM_SLAVE_FORCE_C);
      end if;
   end process P_ETH_MUX;

   -- latch state of dip-switch during reset
   P_ETH_MUX_SWITCH : process ( sysClk156 )
   begin
      if ( rising_edge( sysClk156 ) ) then
         if ( sysRst156 = '1' ) then
            localMac(42 downto 40) <= APP_CORE_CONFIG_C.macAddress(42 downto 40) xor gpioDip(2 downto 0);
            localIp (26 downto 24) <= APP_CORE_CONFIG_C.ipAddress (26 downto 24) xor gpioDip(2 downto 0);
         end if;
      end if;
   end process P_ETH_MUX_SWITCH;

   localMacArray <= (others => localMac);

   -------------------
   -- Application Core
   -------------------
   U_App : entity work.AppTop
      generic map (
         TPD_G             => TPD_G,
         BUILD_INFO_G      => BUILD_INFO_G,
         XIL_DEVICE_G      => "ULTRASCALE",
         AXIL_CLK_FRQ_G    => AXIL_CLK_FRQ_C,
         APP_CORE_CONFIG_G => APP_CORE_CONFIG_C
      )
      port map (
         -- Clock and Reset
         axilClk        => sysClk156,
         axilRst        => sysRst156,

         -- Networking Config.
         localMac       => localMac,
         localIp        => localIp,
         -- AXIS interface
         txMasters      => keptSignals.txMasters,
         txSlaves       => keptSignals.txSlaves,
         rxMasters      => keptSignals.rxMasters,
         rxSlaves       => keptSignals.rxSlaves,

         -- AXI Memory Interface
         axiClk         => axiClk,                              -- [in]
         axiRst         => axiRst,                              -- [in]
         axiWriteMaster => memAxiWriteMaster,                   -- [out]
         axiWriteSlave  => memAxiWriteSlave,                    -- [in]
         axiReadMaster  => memAxiReadMaster,                    -- [out]
         axiReadSlave   => memAxiReadSlave,

         -- ADC Ports
         v0PIn          => v0PIn,
         v0NIn          => v0NIn,
         v2PIn          => v2PIn,
         v2NIn          => v2NIn,
         v8PIn          => v8PIn,
         v8NIn          => v8NIn,
         vPIn           => vPIn,
         vNIn           => vNIn,
         muxAddrOut     => muxAddrLoc,

         -- Fan Port
         fanPwmOut      => fanPwmOut,

         -- IIC Port
         iicScl         => iicScl,
         iicSda         => iicSda,

         timingRefClkP  => refClkP(1),
         timingRefClkN  => refClkN(1),
         timingRxP      => sfpRxP(1),
         timingRxN      => sfpRxN(1),
         timingTxP      => sfpTxP(1),
         timingTxN      => sfpTxN(1),
         appTimingClk   => appTimingClk,
         appTimingRst   => appTimingRst,
         gpioDip        => gpioDip,
         appLeds        => appLeds,
         gpioSmaP       => gpioSmaPBuf,
         gpioSmaN       => gpioSmaNBuf,
         pmod           => pmodBuf
      );

   U_DdrMem : entity work.AmcCarrierDdrMem
      port map (
         -- AXI-Lite Interface
         axilClk           => sysClk156,
         axilRst           => sysRst156,
         axilReadMaster    => AXI_LITE_READ_MASTER_INIT_C,
         axilReadSlave     => open,
         axilWriteMaster   => AXI_LITE_WRITE_MASTER_INIT_C,
         axilWriteSlave    => open,

         memReady          => memReady,
         memError          => open,

         -- AXI4 Interface
         axiClk           => axiClk,
         axiRst           => axiRst,
         axiWriteMaster   => memAxiWriteMaster,
         axiWriteSlave    => memAxiWriteSlave,
         axiReadMaster    => memAxiReadMaster,
         axiReadSlave     => memAxiReadSlave,
         ----------------
         -- Core Ports --
         ----------------
         -- DDR4 Ports
         refClk           => ddrClk300,
         c0_ddr4_adr      => c0_ddr4_adr,
         c0_ddr4_dq       => c0_ddr4_dq,
         c0_ddr4_dm_dbi_n => c0_ddr4_dm_dbi_n,
         c0_ddr4_dqs_c    => c0_ddr4_dqs_c,
         c0_ddr4_dqs_t    => c0_ddr4_dqs_t,
         c0_ddr4_ba       => c0_ddr4_ba,
         c0_ddr4_bg       => c0_ddr4_bg,
         c0_ddr4_cke      => c0_ddr4_cke,
         c0_ddr4_cs_n     => c0_ddr4_cs_n,
         c0_ddr4_odt      => c0_ddr4_odt,
         c0_ddr4_reset_n  => c0_ddr4_reset_n,
         c0_ddr4_act_n    => c0_ddr4_act_n,
         c0_ddr4_ck_c     => c0_ddr4_ck_c,
         c0_ddr4_ck_t     => c0_ddr4_ck_t,
         c0_ddr4_alert_n  => c0_ddr4_alert_n
      );

   ----------------
   -- Misc. Signals
   ----------------
   led(NUM_APP_LEDS_C - 1 downto 0) <= appLeds;

   GEN_LED_7 : if ( NUM_APP_LEDS_C < 8 ) generate
      led(7) <= linkIsUp;
   end generate;

   GEN_LED_6 : if ( NUM_APP_LEDS_C < 7 ) generate
      led(6) <= not speed10_100;             -- lit when 1Gb
   end generate;

   GEN_LED_5 : if ( NUM_APP_LEDS_C < 6 ) generate
      led(5) <= not speed10_100 or speed100; -- lit when 1Gb or 100Mb
   end generate;

   GEN_LED_4 : if ( NUM_APP_LEDS_C < 5 ) generate
      led(4) <= memReady;
   end generate;

   -- Tri-state driver for phyMdio
   phyMdio <= 'Z' when phyMdo = '1' else '0';
   -- Reset line of the external phy
   phyRstN <= extPhyRstN;

   -- SysMon Mux
   muxAddrOut <= muxAddrLoc(2 downto 0);

   -- User SMA
   U_SMAPBUF : IOBUF
      port map (
         io => gpioSmaP,
         i  => gpioSmaPBuf.i,
         o  => gpioSmaPBuf.o,
         t  => gpioSmaPBuf.t
      );

   U_SMANBUF : IOBUF
      port map (
         io => gpioSmaN,
         i  => gpioSmaNBuf.i,
         o  => gpioSmaNBuf.o,
         t  => gpioSmaNBuf.t
      );

   -- PMOD connectors
   GEN_PMODBUF_I : for i in pmod'left downto pmod'right generate
      GEN_PMODBUF_J : for j in pmod(i)'left downto pmod(i)'right generate
         U_PMODBUF : IOBUF
            port map (
               io => pmod(i)(j),
               i  => pmodBuf(i)(j).i,
               o  => pmodBuf(i)(j).o,
               t  => pmodBuf(i)(j).t
            );
      end generate;
   end generate;

   U_ila     : component Ila_256
      port map (
         clk                  => axiClk,
         probe0(31 downto  0) => memAxiReadMaster.araddr(31 downto 0),
         probe0(39 downto 32) => memAxiReadMaster.arlen,
         probe0(42 downto 40) => memAxiReadMaster.arsize,
         probe0(44 downto 43) => memAxiReadMaster.arburst,
         probe0(46 downto 45) => memAxiReadMaster.arlock,
         probe0(49 downto 47) => memAxiReadMaster.arprot,
         probe0(53 downto 50) => memAxiReadMaster.arcache,
         probe0(57 downto 54) => memAxiReadMaster.arqos,
         probe0(58          ) => memAxiReadMaster.arvalid,
         probe0(62 downto 59) => memAxiReadMaster.arregion,
         probe0(63          ) => memAxiReadMaster.rready,


         probe1(58 downto  0) => memAxiReadSlave.rdata(58 downto 0),
         probe1(60 downto 59) => memAxiReadSlave.rresp,
         probe1(61          ) => memAxiReadSlave.rlast,
         probe1(62          ) => memAxiReadSlave.rvalid,
         probe1(63          ) => memAxiReadSlave.arready,

         probe2(31 downto  0) => memAxiWriteMaster.awaddr(31 downto 0),
         probe2(39 downto 32) => memAxiWriteMaster.awlen,
         probe2(42 downto 40) => memAxiWriteMaster.awsize,
         probe2(44 downto 43) => memAxiWriteMaster.awburst,
         probe2(46 downto 45) => memAxiWriteMaster.awlock,
         probe2(49 downto 47) => memAxiWriteMaster.awprot,
         probe2(53 downto 50) => memAxiWriteMaster.awcache,
         probe2(57 downto 54) => memAxiWriteMaster.awqos,
         probe2(58          ) => memAxiWriteMaster.awvalid,
         probe2(62 downto 59) => memAxiWriteMaster.awregion,
         probe2(63          ) => memAxiWriteMaster.bready,


         probe3(47 downto  0) => memAxiWriteMaster.wdata(47 downto 0),
         probe3(53 downto 48) => memAxiWriteMaster.wstrb( 5 downto 0),
         probe3(56 downto 54) => (others => '0'),
         probe3(57          ) => memAxiWriteMaster.wlast,
         probe3(58          ) => memAxiWriteMaster.wvalid,
         probe3(59          ) => memAxiWriteSlave.awready,
         probe3(60          ) => memAxiWriteSlave.wready,
         probe3(62 downto 61) => memAxiWriteSlave.bresp,
         probe3(63          ) => memAxiWriteSlave.bvalid

--       trig_out_ack => '1',
--       trig_in      => '0',
      );

end top_level;
