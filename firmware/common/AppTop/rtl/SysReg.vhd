-------------------------------------------------------------------------------
-- File       : SysReg.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-02-15
-- Last update: 2017-03-17
-------------------------------------------------------------------------------
-- Description:
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.I2cPkg.all;
use work.TimingPkg.all;
use work.AmcCarrierSysRegPkg.all;

library unisim;
use unisim.vcomponents.all;

entity SysReg is
   generic (
      TPD_G            : time             := 1 ns;
      BUILD_INFO_G     : BuildInfoType;
      XIL_DEVICE_G     : string           := "7SERIES";
      USE_SLOWCLK_G    : boolean          := false;
      FIFO_DEPTH_G     : natural          := 0;
      AXIL_CLK_FRQ_G   : real             := 156.25E6;
      USE_TIMING_GTH_G : boolean          := true;
      NUM_TRIGS_G      : natural          := 16
   );
   port (
      -- Clock and Reset
      clk               : in  sl;
      rst               : in  sl;
      -- AXI-Lite interface
      sAxilWriteMaster  : in  AxiLiteWriteMasterArray(2 downto 0);
      sAxilWriteSlave   : out AxiLiteWriteSlaveArray (2 downto 0);
      sAxilReadMaster   : in  AxiLiteReadMasterArray (2 downto 0);
      sAxilReadSlave    : out AxiLiteReadSlaveArray  (2 downto 0);

      bsaWriteMaster    : out AxiLiteWriteMasterType;
      bsaWriteSlave     : in  AxiLiteWriteSlaveType;
      bsaReadMaster     : out AxiLiteReadMasterType;
      bsaReadSlave      : in  AxiLiteReadSlaveType;

      topWriteMasters   : out AxiLiteWriteMasterArray(2 downto 0);
      topWriteSlaves    : in  AxiLiteWriteSlaveArray (2 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
      topReadMasters    : out AxiLiteReadMasterArray (2 downto 0);
      topReadSlaves     : in  AxiLiteReadSlaveArray  (2 downto 0) := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);
 

      ethWriteMaster    : out AxiLiteWriteMasterType;
      ethWriteSlave     : in  AxiLiteWriteSlaveType;
      ethReadMaster     : out AxiLiteReadMasterType;
      ethReadSlave      : in  AxiLiteReadSlaveType;

      -- MB Interface
      obTimingEthMaster : out AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      obTimingEthSlave  : in  AxiStreamSlaveType;
      ibTimingEthMaster : in  AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      ibTimingEthSlave  : out AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;
      -- ADC Ports
      v0PIn             : in  sl;
      v0NIn             : in  sl;
      v2PIn             : in  sl;
      v2NIn             : in  sl;
      v8PIn             : in  sl;
      v8NIn             : in  sl;
      vPIn              : in  sl;
      vNIn              : in  sl;
      muxAddrOut        : out slv(4 downto 0) := (others => '0');
      -- Fan
      fanPwmOut         : out sl := '1';
      -- IIC Port
      iicScl            : inout sl;
      iicSda            : inout sl;
      -- Timing
      timingRefClkP     : in  sl := '0';
      timingRefClkN     : in  sl := '1';
      timingRxP         : in  sl := '0';
      timingRxN         : in  sl := '0';
      timingTxP         : out sl := '0';
      timingTxN         : out sl := '1';

      recTimingClk      : out sl;
      recTimingRst      : out sl;

      appTimingClk      : in  sl;
      appTimingRst      : in  sl;
      appTimingBus      : out TimingBusType;
      appTimingTrig     : out TimingTrigType
      );
end SysReg;

architecture mapping of SysReg is

   constant SHARED_MEM_WIDTH_C : positive                           := 10;
   constant IRQ_ADDR_C         : slv(SHARED_MEM_WIDTH_C-1 downto 0) := (others => '1');

   signal tAxilWriteMaster  : AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
   signal tAxilWriteSlave   : AxiLiteWriteSlaveType;
   signal tAxilReadMaster   : AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
   signal tAxilReadSlave    : AxiLiteReadSlaveType;

   signal fAxilWriteMaster  : AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
   signal fAxilWriteSlave   : AxiLiteWriteSlaveType;
   signal fAxilReadMaster   : AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
   signal fAxilReadSlave    : AxiLiteReadSlaveType;


   signal mAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal mAxilWriteSlaves  : AxiLiteWriteSlaveArray (NUM_AXI_MASTERS_C-1 downto 0) := ( others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C );
   signal mAxilReadMasters  : AxiLiteReadMasterArray (NUM_AXI_MASTERS_C-1 downto 0);
   signal mAxilReadSlaves   : AxiLiteReadSlaveArray  (NUM_AXI_MASTERS_C-1 downto 0)  := ( others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C );

   signal timingRefDiv2     : sl;
   signal timingRefClk      : sl := '0';
   signal timingRefClkDiv2  : sl := '0';
   signal timingRecClk      : sl := '0';
   signal timingRecRst      : sl := '1';
   signal timingTxUsrClk    : sl := '0';
   signal timingTxUsrRst    : sl := '1';
   signal timingCdrStable   : sl;
   signal timingLoopback    : slv(2 downto 0) := "000";
   signal timingClkSel      : sl;
   signal timingLoopbackSel : slv(2 downto 0) := "000";

   signal timingTxPhy       : TimingPhyType;
   signal timingTxPhyLoc    : TimingPhyType;
   signal timingRxPhy       : TimingRxType;
   signal timingRxControlI  : TimingPhyControlType;
   signal timingRxStatus    : TimingPhyStatusType := TIMING_PHY_STATUS_INIT_C;
   signal timingTxStatus    : TimingPhyStatusType := TIMING_PHY_STATUS_INIT_C;
   signal timingTxRstAsync  : sl;

   signal timingBus         : TimingBusType;
   signal appTimingMode     : sl;


   constant NUM_I2C_DEVS_C  : natural := 5;

   constant I2C_DEVICE_MAP_C: I2cAxiLiteDevArray(0 to NUM_I2C_DEVS_C-1) := (
      0 => (MakeI2cAxiLiteDevType("1110100", 8, 0, '1')), -- TCA9548
      1 => (MakeI2cAxiLiteDevType("1011101", 8, 8, '1')), -- Si570
      2 => (MakeI2cAxiLiteDevType("1110101", 8, 0, '1')), -- PCA9544
      3 => (MakeI2cAxiLiteDevType("1010000", 8, 8, '1')), -- SFP 0/1
      4 => (MakeI2cAxiLiteDevType("1101000", 8, 8, '1'))  -- Si5328
   );

   constant TCASW_AXIL_BASE_ADDR_C : slv(31 downto 0)  :=
         unsigned(SYSREG_MASTERS_CONFIG_C(IIC_MAS_INDEX_C).baseAddr) + 0*1024;
   constant SI570_AXIL_BASE_ADDR_C : slv(31 downto 0)  :=
         unsigned(SYSREG_MASTERS_CONFIG_C(IIC_MAS_INDEX_C).baseAddr) + 1*1024;
   constant SI5328_AXIL_BASE_ADDR_C : slv(31 downto 0) :=
         unsigned(SYSREG_MASTERS_CONFIG_C(IIC_MAS_INDEX_C).baseAddr) + 4*1024;

begin

   ---------------------------
   -- AXI-Lite Crossbar Module
   ---------------------------
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 5,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => SYSREG_MASTERS_CONFIG_C)
      port map (
         sAxiWriteMasters(0) => sAxilWriteMaster(0),
         sAxiWriteMasters(1) => sAxilWriteMaster(1),
         sAxiWriteMasters(2) => sAxilWriteMaster(2),
         sAxiWriteMasters(3) => tAxilWriteMaster,
         sAxiWriteMasters(4) => fAxilWriteMaster,
         sAxiWriteSlaves(0)  => sAxilWriteSlave(0),
         sAxiWriteSlaves(1)  => sAxilWriteSlave(1),
         sAxiWriteSlaves(2)  => sAxilWriteSlave(2),
         sAxiWriteSlaves(3)  => tAxilWriteSlave,
         sAxiWriteSlaves(4)  => fAxilWriteSlave,
         sAxiReadMasters(0)  => sAxilReadMaster(0),
         sAxiReadMasters(1)  => sAxilReadMaster(1),
         sAxiReadMasters(2)  => sAxilReadMaster(2),
         sAxiReadMasters(3)  => tAxilReadMaster,
         sAxiReadMasters(4)  => fAxilReadMaster,
         sAxiReadSlaves(0)   => sAxilReadSlave(0),
         sAxiReadSlaves(1)   => sAxilReadSlave(1),
         sAxiReadSlaves(2)   => sAxilReadSlave(2),
         sAxiReadSlaves(3)   => tAxilReadSlave,
         sAxiReadSlaves(4)   => fAxilReadSlave,
         mAxiWriteMasters    => mAxilWriteMasters,
         mAxiWriteSlaves     => mAxilWriteSlaves,
         mAxiReadMasters     => mAxilReadMasters,
         mAxiReadSlaves      => mAxilReadSlaves,
         axiClk              => clk,
         axiClkRst           => rst);

   ---------------------------
   -- AXI-Lite: Version Module
   ---------------------------
   U_AxiVersion : entity work.AxiVersion
      generic map (
         TPD_G            => TPD_G,
         BUILD_INFO_G     => BUILD_INFO_G,
         CLK_PERIOD_G     => (1.0/AXIL_CLK_FRQ_G),
         XIL_DEVICE_G     => XIL_DEVICE_G,
         EN_DEVICE_DNA_G  => true,
         USE_SLOWCLK_G    => USE_SLOWCLK_G)
      port map (
         axiReadMaster  => mAxilReadMasters(VERSION_INDEX_C),
         axiReadSlave   => mAxilReadSlaves(VERSION_INDEX_C),
         axiWriteMaster => mAxilWriteMasters(VERSION_INDEX_C),
         axiWriteSlave  => mAxilWriteSlaves(VERSION_INDEX_C),
         axiClk         => clk,
         axiRst         => rst);

   GEN_7SERIES : if (XIL_DEVICE_G = "7SERIES") generate
      ------------------------
      -- AXI-Lite: XADC Module
      ------------------------
      U_XADC : entity work.AxiXadcWrapper
         generic map (
            TPD_G            => TPD_G
         )
         port map (
            axiReadMaster  => mAxilReadMasters(XADC_INDEX_C),
            axiReadSlave   => mAxilReadSlaves(XADC_INDEX_C),
            axiWriteMaster => mAxilWriteMasters(XADC_INDEX_C),
            axiWriteSlave  => mAxilWriteSlaves(XADC_INDEX_C),
            axiClk         => clk,
            axiRst         => rst,
            vPIn           => vPIn,
            vNIn           => vNIn);
   end generate;

   GEN_ULTRA_SCALE : if (XIL_DEVICE_G = "ULTRASCALE") generate
      signal sysmonAlarm, otAlarm, tempAlarm : sl;
   begin
      --------------------------
      -- AXI-Lite: SYSMON Module
      --------------------------
      U_SysMon : entity work.SystemManagementWrapper
         generic map (
            TPD_G => TPD_G
         )
         port map (
            axiReadMaster  => mAxilReadMasters(SYS_MON_INDEX_C),
            axiReadSlave   => mAxilReadSlaves(SYS_MON_INDEX_C),
            axiWriteMaster => mAxilWriteMasters(SYS_MON_INDEX_C),
            axiWriteSlave  => mAxilWriteSlaves(SYS_MON_INDEX_C),
            axiClk         => clk,
            axiRst         => rst,
            v0PIn          => v0PIn,
            v0NIn          => v0NIn,
            v2PIn          => v2PIn,
            v2NIn          => v2NIn,
            v8PIn          => v8PIn,
            v8NIn          => v8NIn,
            vPIn           => vPIn,
            vNIn           => vNIn,
            muxAddrOut     => muxAddrOut,
            tempAlarmOut   => tempAlarm,
            otOut          => otAlarm
         );

      sysmonAlarm <= otAlarm or tempAlarm;

      U_FanCtrl : entity work.AxilFanController
         generic map (
            TPD_G               => TPD_G,
            SYSMON_BASE_ADDR_G  => SYSREG_MASTERS_CONFIG_C(SYS_MON_INDEX_C).baseAddr,
            AXIL_FREQ_G         => AXIL_CLK_FRQ_G
         )
         port map (
            axilClk          => clk,
            axilRst          => rst,

            mAxilReadMaster  => fAxilReadMaster,
            mAxilReadSlave   => fAxilReadSlave,

            sAxilReadMaster  => mAxilReadMasters (FAN_INDEX_C),
            sAxilReadSlave   => mAxilReadSlaves  (FAN_INDEX_C),
            sAxilWriteMaster => mAxilWriteMasters(FAN_INDEX_C),
            sAxilWriteSlave  => mAxilWriteSlaves (FAN_INDEX_C),

            sysmonAlarm      => sysmonAlarm,
            fanPwm           => fanPwmOut
         );

   end generate;

   -- IIC Master
   U_AxiI2cRegMaster : entity work.AxiI2cRegMaster
      generic map (
         TPD_G              => TPD_G,
         DEVICE_MAP_G       => I2C_DEVICE_MAP_C,
         AXI_CLK_FREQ_G     => AXIL_CLK_FRQ_G
      )
      port map (
         scl                => iicScl,
         sda                => iicSda,

         axiClk             => clk,
         axiRst             => rst,

         axiReadMaster      => mAxilReadMasters(IIC_MAS_INDEX_C),
         axiReadSlave       => mAxilReadSlaves(IIC_MAS_INDEX_C),
         axiWriteMaster     => mAxilWriteMasters(IIC_MAS_INDEX_C),
         axiWriteSlave      => mAxilWriteSlaves(IIC_MAS_INDEX_C)
      );

   U_TimingCore : entity work.TimingCore
      generic map (
         TPD_G               => TPD_G,
         STREAM_L1_G         => true,
         AXIL_RINGB_G        => false,
         ASYNC_G             => false,
         AXIL_BASE_ADDR_G    => SYSREG_MASTERS_CONFIG_C(TIMCORE_INDEX_C).baseAddr
      )
      port map (
         gtTxUsrClk          => timingTxUsrClk,
         gtTxUsrRst          => timingTxUsrRst,

         gtRxRecClk          => timingRecClk,
         gtRxData            => timingRxPhy.data,
         gtRxDataK           => timingRxPhy.dataK,
         gtRxDispErr         => timingRxPhy.dspErr,
         gtRxDecErr          => timingRxPhy.decErr,
         gtRxControl         => timingRxControlI,
         gtRxStatus          => timingRxStatus,
         gtTxReset           => open, -- not useful; if the TX is reset the TPGMini regs dont' work
         gtLoopback          => timingLoopbackSel,

         timingPhy           => timingTxPhy,
         timingClkSel        => timingClkSel,

         appTimingClk        => appTimingCLk,
         appTimingRst        => appTimingRst,
         appTimingBus        => timingBus,
         appTimingMode       => appTimingMode,

         axilClk             => clk,
         axilRst             => rst,
         axilReadMaster      => mAxilReadMasters (TIMCORE_INDEX_C),
         axilReadSlave       => mAxilReadSlaves  (TIMCORE_INDEX_C),
         axilWriteMaster     => mAxilWriteMasters(TIMCORE_INDEX_C),
         axilWriteSlave      => mAxilWriteSlaves (TIMCORE_INDEX_C),

         ibEthMsgMaster      => ibTimingEthMaster,
         ibEthMsgSlave       => ibTimingEthSlave,

         obEthMsgMaster      => obTimingEthMaster,
         obEthMsgSlave       => obTimingEthSlave
      );

   U_EvrV2 : entity work.EvrV2CoreTriggers
      generic map (
         TPD_G               => TPD_G,
         NCHANNELS_G         => NUM_TRIGS_G, -- event selectors
         NTRIGGERS_G         => NUM_TRIGS_G,
         TRIG_DEPTH_G        => 19,
         COMMON_CLK_G        => false,
         AXIL_BASEADDR_G     => SYSREG_MASTERS_CONFIG_C(TIM_TRG_INDEX_C).baseAddr
      )
      port map (
         -- AXI-Lite and IRQ Interface
         axilClk             => clk,
         axilRst             => rst,
         axilReadMaster      => mAxilReadMasters (TIM_TRG_INDEX_C),
         axilReadSlave       => mAxilReadSlaves  (TIM_TRG_INDEX_C),
         axilWriteMaster     => mAxilWriteMasters(TIM_TRG_INDEX_C),
         axilWriteSlave      => mAxilWriteSlaves (TIM_TRG_INDEX_C),
         -- EVR Ports
         evrClk              => appTimingClk,
         evrRst              => appTimingRst,
         evrBus              => timingBus,
         -- Trigger and Sync Port
         trigOut             => appTimingTrig, -- out slv(11 downto 0);
         evrModeSel          => appTimingMode
      );

   P_TIMING_PHY : process( timingTxPhy, timingTxRstAsync ) is
      variable v : TimingPhyType;
   begin
      v                  := timingTxPhy;
      v.control.pllReset := timingTxPhy.control.pllReset or timingTxRstAsync;

      timingTxPhyLoc     <= v;
   end process P_TIMING_PHY;

   GEN_TIMING_GTH: if (USE_TIMING_GTH_G) generate

      signal timingRxRst      : sl;
      signal timingRxControlO : TimingPhyControlType;

   begin

   -- splice in local reset signal
   -- the timingRxControl.reset signal is in the axilClk domain;
   -- so is the rxRst produced by the TimingClockSwitcher.
   P_TIMING_RX_RST : process(timingRxControlI, timingRxRst) is
      variable v : TimingPhyControlType;
   begin
      v       := timingRxControlI;
      v.reset := timingRxControlI.reset or timingRxRst;
      timingRxControlO <= v;
   end process P_TIMING_RX_RST;

   U_TimingRefClk_IBUFDS : IBUFDS_GTE3
      generic map (
         REFCLK_EN_TX_PATH  => '0',
         REFCLK_HROW_CK_SEL => "01",
         REFCLK_ICNTL_RX    => "00"
      )
      port map (
         I                => timingRefClkP,
         IB               => timingRefClkN,
         CEB              => '0',
         ODIV2            => timingRefDiv2,
         O                => timingRefClk
      );

   U_TimingRefClkDiv2_BUFG : BUFG_GT
      port map (
         I                => timingRefDiv2,
         CE               => '1',
         CEMASK           => '1',
         CLR              => '0',
         CLRMASK          => '1',
         DIV              => "000",
         O                => timingRefClkDiv2
      );

   U_TimingGTH : entity work.TimingGtCoreWrapper
      generic map (
         TPD_G            => TPD_G,
         AXIL_BASE_ADDR_G => SYSREG_MASTERS_CONFIG_C(TIM_GTH_INDEX_C).baseAddr
      )
      port map (
         axilClk          => clk,
         axilRst          => rst,

         axilReadMaster   => mAxilReadMasters(TIM_GTH_INDEX_C),
         axilReadSlave    => mAxilReadSlaves(TIM_GTH_INDEX_C),
         axilWriteMaster  => mAxilWriteMasters(TIM_GTH_INDEX_C),
         axilWriteSlave   => mAxilWriteSlaves(TIM_GTH_INDEX_C),

         stableClk        => clk,
         stableRst        => rst,

         gtRefClk         => timingRefClk,
         gtRefClkDiv2     => timingRefClkDiv2,

         gtRxP            => timingRxP,
         gtRxN            => timingRxN,
         gtTxP            => timingTxP,
         gtTxN            => timingTxN,

         rxControl        => timingRxControlO,
         rxStatus         => timingRxStatus,
         rxUsrClkActive   => '1',
         rxCdrStable      => timingCdrStable,
         rxUsrClk         => timingRecClk,
         rxData           => timingRxPhy.data,
         rxDataK          => timingRxPhy.dataK,
         rxDispErr        => timingRxPhy.dspErr,
         rxDecErr         => timingRxPhy.decErr,
         rxOutClk         => timingRecClk,

         txControl        => timingTxPhyLoc.control,
         txStatus         => timingTxStatus,
         txUsrClk         => timingTxUsrClk,
         txUsrClkActive   => '1',
         txData           => timingTxPhyLoc.data,
         txDataK          => timingTxPhyLoc.dataK,
         txOutClk         => timingTxUsrClk,
         loopback         => timingLoopbackSel
      );

      timingTxUsrRst <= not(timingTxStatus.resetDone);
      timingRecRst   <= not(timingRxStatus.resetDone);

      -- You can also use the Si570 chip to generate the timing refclock;
      --  a) use the 'TimingClkSwitcherSi570' architecture
      --  b) use CLOCK_AXIL_BASE_ADDR_G => SI570_AXIL_BASE_ADDR_C
      --  c) update the toplevel constraints so that the timing GTH
      --     takes its clock from the correct MGTREFCLK inputs.

      U_TimingClkSwitcher : entity work.TimingClkSwitcher(TimingClkSwitcherSi5328)
         generic map (
            TPD_G                  => TPD_G,
            CLOCK_AXIL_BASE_ADDR_G => SI5328_AXIL_BASE_ADDR_C,
            TCASW_AXIL_BASE_ADDR_G => TCASW_AXIL_BASE_ADDR_C,
            AXIL_FREQ_G            => AXIL_CLK_FRQ_G
         )
         port map (
            axilClk                => clk,
            axilRst                => rst,

            clkSel                 => timingClkSel, -- timingClkSel already in AXIL domain

            txRst                  => timingTxRstAsync,
            rxRst                  => timingRxRst,

            mAxilReadMaster        => tAxilReadMaster,
            mAxilReadSlave         => tAxilReadSlave,
            mAxilWriteMaster       => tAxilWriteMaster,
            mAxilWriteSlave        => tAxilWriteSlave,

            sAxilReadMaster        => mAxilReadMasters (TCLKSWI_INDEX_C),
            sAxilReadSlave         => mAxilReadSlaves  (TCLKSWI_INDEX_C),
            sAxilWriteMaster       => mAxilWriteMasters(TCLKSWI_INDEX_C),
            sAxilWriteSlave        => mAxilWriteSlaves (TCLKSWI_INDEX_C)
          );

   end generate;

   NO_GEN_TIMING_GTH : if (not USE_TIMING_GTH_G) generate
   signal timingClkLcls1 : sl;
   signal timingClkLcls2 : sl;
   signal timingRstLcls1 : sl;
   signal timingRstLcls2 : sl;
   begin

   U_SimTimingClock : entity work.SimTimingClkGen
      port map (
         clk156p25          => clk,
         rst156p25          => rst,

         timingClkLcls1     => timingClkLcls1,
         timingClkLcls2     => timingClkLcls2,

         timingRstLcls1     => timingRstLcls1,
         timingRstLcls2     => timingRstLcls2
      );

   U_TimingClkMux : BUFGMUX_CTRL
      port map (
         I0 => timingClkLcls1,
         I1 => timingClkLcls2,
         S  => timingClkSel,
         O  => timingTxUsrClk
      );

   timingTxUsrRst           <= timingRstLcls2 when timingClkSel = '1' else timingRstLcls1;

   timingRxStatus.resetDone <= '1';

   timingRxPhy.data         <= timingTxPhyLoc.data;
   timingRxPhy.dataK        <= timingTxPhyLoc.dataK;
   timingRxPhy.dspErr       <= (others => '0');
   timingRxPhy.decErr       <= (others => '0');

   timingRecClk             <= timingTxUsrClk;
   timingRecRst             <= timingTxUsrRst;

   timingTxRstAsync         <= '0';

   end generate;

   recTimingClk                   <= timingRecClk;
   recTimingRst                   <= timingRecRst;
   appTimingBus                   <= timingBus;

   bsaWriteMaster                 <= mAxilWriteMasters(BSA_INDEX_C);
   mAxilWriteSlaves (BSA_INDEX_C) <= bsaWriteSlave;
   bsaReadMaster                  <= mAxilReadMasters (BSA_INDEX_C);
   mAxilReadSlaves  (BSA_INDEX_C) <= bsaReadSlave;

   ethWriteMaster                 <= mAxilWriteMasters(ETH_INDEX_C);
   mAxilWriteSlaves (ETH_INDEX_C) <= ethWriteSlave;
   ethReadMaster                  <= mAxilReadMasters (ETH_INDEX_C);
   mAxilReadSlaves  (ETH_INDEX_C) <= ethReadSlave;

   topWriteMasters(0)             <= mAxilWriteMasters(APP_INDEX_C);
   mAxilWriteSlaves (APP_INDEX_C) <= topWriteSlaves(0);
   topReadMasters(0)              <= mAxilReadMasters (APP_INDEX_C);
   mAxilReadSlaves  (APP_INDEX_C) <= topReadSlaves(0);

   topWriteMasters(1)             <= mAxilWriteMasters(GIG_INDEX_C);
   mAxilWriteSlaves (GIG_INDEX_C) <= topWriteSlaves(1);
   topReadMasters(1)              <= mAxilReadMasters (GIG_INDEX_C);
   mAxilReadSlaves  (GIG_INDEX_C) <= topReadSlaves(1);

   topWriteMasters(2)             <= mAxilWriteMasters(GTH_INDEX_C);
   mAxilWriteSlaves (GTH_INDEX_C) <= topWriteSlaves(2);
   topReadMasters(2)              <= mAxilReadMasters (GTH_INDEX_C);
   mAxilReadSlaves  (GTH_INDEX_C) <= topReadSlaves(2);

end mapping;
