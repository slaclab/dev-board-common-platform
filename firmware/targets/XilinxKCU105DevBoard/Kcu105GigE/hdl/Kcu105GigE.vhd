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
use work.AxiPkg.all;
use work.EthMacPkg.all;
use work.SsiPkg.all;
use work.TimingPkg.all;

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
      iicMuxRstL : out   sl
   );
end Kcu105GigE;

architecture top_level of Kcu105GigE is

   constant AXIS_SIZE_C : positive         := 1;
   constant IP_ADDR_C   : slv(31 downto 0) := x"0A02A8C0";          -- 192.168.2.10
   constant MAC_ADDR_C  : slv(47 downto 0) := x"010300564400";      -- 00:44:56:00:03:01
   constant RST_DEL_C   : slv(22 downto 0) := toSlv(16#3FFFFF#,23); -- ~ 2*10ms @ 156MHz

   constant AXIL_CLK_FRQ_C : real := 156.25E6;

   -- Mem read word size is 32 bits
   constant MEM_AXI_CONFIG_C : AxiConfigType := (
      ADDR_WIDTH_C => 31,
      DATA_BYTES_C => 4,
      ID_BITS_C    => 4,
      LEN_BITS_C   => 8);

   constant AXI_STRM_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(8);


   type MuxedSignalsType is record
      txMasters     : AxiStreamMasterArray(AXIS_SIZE_C-1 downto 0);
      txSlaves      : AxiStreamSlaveArray(AXIS_SIZE_C-1 downto 0);
      rxMasters     : AxiStreamMasterArray(AXIS_SIZE_C-1 downto 0);
      rxSlaves      : AxiStreamSlaveArray(AXIS_SIZE_C-1 downto 0);
      phyReady      : sl;
   end record;

   signal muxedSignals  : MuxedSignalsType;

   signal txMastersGTH  : AxiStreamMasterArray(AXIS_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal txSlavesGTH   : AxiStreamSlaveArray(AXIS_SIZE_C-1 downto 0);
   signal rxMastersGTH  : AxiStreamMasterArray(AXIS_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal rxSlavesGTH   : AxiStreamSlaveArray(AXIS_SIZE_C-1 downto 0);
   signal txMastersSGMII: AxiStreamMasterArray(AXIS_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal txSlavesSGMII : AxiStreamSlaveArray(AXIS_SIZE_C-1 downto 0);
   signal rxMastersSGMII: AxiStreamMasterArray(AXIS_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal rxSlavesSGMII : AxiStreamSlaveArray(AXIS_SIZE_C-1 downto 0);



   signal sgmiiClk      : sl;
   signal sgmiiRst      : sl;
   signal gthRstExt     : sl;
   signal sgmiiRstExt   : sl;

   signal sgmiiPhyReady : sl;
   signal gthPhyReady   : sl := '0';

   signal selSGMII      : sl;

   signal gthDmaRst     : sl;
   signal sgmiiDmaRst   : sl;

   signal phyMdo        : sl := '1';

   signal axiClk        : sl;
   signal axiRst        : sl;

   signal sysClk300NB   : sl;
   signal ddrClk300     : sl;
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

   signal appTxMaster   : AxiStreamMasterType;
   signal appRxMaster   : AxiStreamMasterType;
   signal appTxSlave    : AxiStreamSlaveType;
   signal appRxSlave    : AxiStreamSlaveType;

   signal initDone      : sl := '0';

   signal memReady      : sl;

   signal memAxiWriteMaster    : AxiWriteMasterType;
   signal memAxiWriteSlave     : AxiWriteSlaveType;
   signal memAxiReadMaster     : AxiReadMasterType;
   signal memAxiReadSlave      : AxiReadSlaveType;
   
   signal appTimingClk         : sl;
   signal appTimingRst         : sl;

   constant CNT_LEN_C          : natural := 28;
   signal rxClkCnt             : slv(CNT_LEN_C-1 downto 0) := (others => '0');
   signal txClkCnt             : slv(CNT_LEN_C-1 downto 0) := (others => '0');

   constant NUM_LANE_C         : natural := 1;
   
   signal    dmaClk            : slv(NUM_LANE_C-1 downto 0);
   signal    dmaRst            : slv(NUM_LANE_C-1 downto 0);

   signal    dbg               : slv(1 downto 0);
   signal    dbgi              : slv(1 downto 0);


   attribute dont_touch                 : string;
   attribute dont_touch of muxedSignals : signal is "TRUE";
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

         rstOut(0)        => sysRst156,

         locked           => sysMmcmLocked
      );

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
      
   dmaClk <= (others => sysClk156);
   dmaRst <= (others => sgmiiDmaRst);

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
         dmaClk             => dmaClk,
         dmaRst             => dmaRst,
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
         TPD_G          => TPD_G,
         BUILD_INFO_G   => BUILD_INFO_G,
         XIL_DEVICE_G   => "ULTRASCALE",
         APP_TYPE_G     => "ETH",
         AXIS_SIZE_G    => AXIS_SIZE_C,
         MAC_ADDR_G     => MAC_ADDR_C,
         IP_ADDR_G      => IP_ADDR_C,
         APP_STRM_CFG_G => AXI_STRM_CONFIG_C,
         AXIL_CLK_FRQ_G => AXIL_CLK_FRQ_C)
      port map (
         -- Clock and Reset
         clk            => sysClk156,
         rst            => sysRst156,
         -- AXIS interface
         txMasters      => muxedSignals.txMasters,
         txSlaves       => muxedSignals.txSlaves,
         rxMasters      => muxedSignals.rxMasters,
         rxSlaves       => muxedSignals.rxSlaves,

         -- App Stream Interface
         appTxMaster    => appTxMaster,    -- in  AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
         appTxSlave     => appTxSlave,     -- out AxiStreamSlaveType;
         appRxMaster    => appRxMaster,    -- out AxiStreamMasterType;
         appRxSlave     => appRxSlave,     -- in  AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;

         -- ADC Ports
         vPIn           => vPIn,
         vNIn           => vNIn,

         -- IIC Port
         iicScl         => iicScl,
         iicSda         => iicSda,

         timingRefClkP  => ethClkP,
         timingRefClkN  => ethClkN,
         timingRxP      => ethRxP,
         timingRxN      => ethRxN,
         timingTxP      => ethTxP,
         timingTxN      => ethTxN,
         appTimingClk   => appTimingClk,
         appTimingRst   => appTimingRst,
         dbg            => dbg,
         dbgi           => dbgi
         );

   dbgi(1) <= '0';
   dbgi(0) <= gpioDip(1);

   U_SrpV3Axi_1 : entity work.SrpV3Axi
      generic map (
         TPD_G               => TPD_G,
         PIPE_STAGES_G       => 1,
         FIFO_PAUSE_THRESH_G => 128,
         TX_VALID_THOLD_G    => 256,-- Pre-cache threshold set 256 out of 512 (prevent holding the ETH link during AXI-lite transactions)
         SLAVE_READY_EN_G    => true,
         GEN_SYNC_FIFO_G     => false,
         AXI_CLK_FREQ_G      => 200.0E+6,
         AXI_CONFIG_G        => MEM_AXI_CONFIG_C,
--          AXI_BURST_G         => AXI_BURST_G,
--          AXI_CACHE_G         => AXI_CACHE_G,
         ACK_WAIT_BVALID_G   => false,
         AXI_STREAM_CONFIG_G => AXI_STRM_CONFIG_C,
         UNALIGNED_ACCESS_G  => false,
         BYTE_ACCESS_G       => false,
         WRITE_EN_G          => true,
         READ_EN_G           => true)
      port map (
         sAxisClk       => sysClk156,                           -- [in]
         sAxisRst       => sysRst156,                           -- [in]
         sAxisMaster    => appRxMaster,                         -- [in]
         sAxisSlave     => appRxSlave,                          -- [out]
         sAxisCtrl      => open,                                -- [out]
         mAxisClk       => sysClk156,                           -- [in]
         mAxisRst       => sysRst156,                           -- [in]
         mAxisMaster    => appTxMaster,                         -- [out]
         mAxisSlave     => appTxSlave,                          -- [in]

         axiClk         => axiClk,                              -- [in]
         axiRst         => axiRst,                              -- [in]
         axiWriteMaster => memAxiWriteMaster,                   -- [out]
         axiWriteSlave  => memAxiWriteSlave,                    -- [in]
         axiReadMaster  => memAxiReadMaster,                    -- [out]
         axiReadSlave   => memAxiReadSlave);                    -- [in]

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
   -- IIC Bus (deassert MUX/Switch reset)
   ----------------

   iicMuxRstL <= '1';

   P_CNT_RX : process( appTimingClk ) is
   begin
      if ( rising_edge( appTimingClk ) ) then
         rxClkCnt <= slv( unsigned( rxClkCnt ) + 1 );
      end if;
   end process P_CNT_RX;

   P_CNT_TX : process( dbg(1) ) is
   begin
      if ( rising_edge( dbg(1) ) ) then
         txClkCnt <= slv( unsigned( txClkCnt ) + 1 );
      end if;
   end process P_CNT_TX;


   ----------------
   -- Misc. Signals
   ----------------
   led(7) <= linkIsUp;
   led(6) <= not speed10_100;             -- lit when 1Gb
   led(5) <= not speed10_100 or speed100; -- lit when 1Gb or 100Mb
   led(4) <= memReady;
   led(3) <= initDone;
   led(2) <= rxClkCnt( rxClkCnt'left );
   led(1) <= txClkCnt( txClkCnt'left );
   led(0) <= dbg(0);

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
         clk          => sysClk156
--       trig_out_ack => '1',
--       trig_in      => '0',
      );

end top_level;
