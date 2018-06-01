-------------------------------------------------------------------------------
-- File       : AppReg.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-02-15
-- Last update: 2017-03-17
-------------------------------------------------------------------------------
-- Description:
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

entity AppReg is
   generic (
      TPD_G            : time             := 1 ns;
      BUILD_INFO_G     : BuildInfoType;
      XIL_DEVICE_G     : string           := "7SERIES";
      AXI_ERROR_RESP_G : slv( 1 downto 0) := AXI_RESP_DECERR_C;
      USE_SLOWCLK_G    : boolean          := false;
      FIFO_DEPTH_G     : natural          := 0;
      AXIL_CLK_FRQ_G   : real             := 156.25E6;
      GEN_TIMING_GTH_G : boolean          := true;
      NUM_TRIGS_G      : natural          := 16
   );
   port (
      -- Clock and Reset
      clk             : in  sl;
      rst             : in  sl;
      -- AXI-Lite interface
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;

      bsaWriteMaster  : out AxiLiteWriteMasterType;
      bsaWriteSlave   : in  AxiLiteWriteSlaveType;
      bsaReadMaster   : out AxiLiteReadMasterType;
      bsaReadSlave    : in  AxiLiteReadSlaveType;

      appWriteMaster  : out AxiLiteWriteMasterType;
      appWriteSlave   : in  AxiLiteWriteSlaveType;
      appReadMaster   : out AxiLiteReadMasterType;
      appReadSlave    : in  AxiLiteReadSlaveType;

      -- MB Interface
      obTimingEthMaster : out AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      obTimingEthSlave  : in  AxiStreamSlaveType;
      ibTimingEthMaster : in  AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      ibTimingEthSlave  : out AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;
      -- ADC Ports
      vPIn            : in  sl;
      vNIn            : in  sl;
      -- IIC Port
      iicScl          : inout sl;
      iicSda          : inout sl;
      -- Timing
      timingRefClkP   : in  sl := '0';
      timingRefClkN   : in  sl := '1';
      timingRxP       : in  sl := '0';
      timingRxN       : in  sl := '0';
      timingTxP       : out sl := '0';
      timingTxN       : out sl := '1';

      recTimingClk    : out sl;
      recTimingRst    : out sl;

      appTimingClk    : in  sl;
      appTimingRst    : in  sl;
      appTimingBus    : out TimingBusType;
      appTimingTrig   : out TimingTrigType;
      dbg             : out slv(1 downto 0);
      dbgi            : in  slv(1 downto 0)
      );
end AppReg;

architecture mapping of AppReg is

   constant SHARED_MEM_WIDTH_C : positive                           := 10;
   constant IRQ_ADDR_C         : slv(SHARED_MEM_WIDTH_C-1 downto 0) := (others => '1');

   signal mAxilWriteMaster  : AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
   signal mAxilWriteSlave   : AxiLiteWriteSlaveType;
   signal mAxilReadMaster   : AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
   signal mAxilReadSlave    : AxiLiteReadSlaveType;

   signal mAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal mAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0) := ( others => AXI_LITE_WRITE_SLAVE_INIT_C );
   signal mAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal mAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0)  := ( others => AXI_LITE_READ_SLAVE_INIT_C );

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
   signal timingRxControl   : TimingPhyControlType;
   signal timingRxStatus    : TimingPhyStatusType := TIMING_PHY_STATUS_INIT_C;
   signal timingTxStatus    : TimingPhyStatusType := TIMING_PHY_STATUS_INIT_C;
   signal timingTxRstAsync  : sl;

   signal timingBus         : TimingBusType;
   signal exptBus           : ExptBusType;
   signal appTimingMode     : sl;


   constant NUM_I2C_DEVS_C  : natural := 4;

   constant I2C_DEVICE_MAP_C: I2cAxiLiteDevArray(0 to NUM_I2C_DEVS_C-1) := (
      0 => (MakeI2cAxiLiteDevType("1110100", 8, 0, '1')), -- TCA9548
      1 => (MakeI2cAxiLiteDevType("1011101", 8, 8, '1')), -- SI570
      2 => (MakeI2cAxiLiteDevType("1110101", 8, 0, '1')), -- PCA9544
      3 => (MakeI2cAxiLiteDevType("1010000", 8, 8, '1')) -- SFP 0/1
   );

   constant TCASW_AXIL_BASE_ADDR_C : slv(31 downto 0) :=
         unsigned(SYSREG_MASTERS_CONFIG_C(IIC_MAS_INDEX_C).baseAddr) + 0*1024;
   constant SI570_AXIL_BASE_ADDR_C : slv(31 downto 0) :=
         unsigned(SYSREG_MASTERS_CONFIG_C(IIC_MAS_INDEX_C).baseAddr) + 1*1024;

begin

   ---------------------------
   -- AXI-Lite Crossbar Module
   ---------------------------
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
         NUM_SLAVE_SLOTS_G  => 2,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => SYSREG_MASTERS_CONFIG_C)
      port map (
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteMasters(1) => mAxilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiWriteSlaves(1)  => mAxilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadMasters(1)  => mAxilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         sAxiReadSlaves(1)   => mAxilReadSlave,
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
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
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
            TPD_G            => TPD_G,
            AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
         port map (
            axiReadMaster  => mAxilReadMasters(XADC_INDEX_C),
            axiReadSlave   => mAxilReadSlaves(XADC_INDEX_C),
            axiWriteMaster => mAxilWriteMasters(XADC_INDEX_C),
            axiWriteSlave  => mAxilWriteSlaves(XADC_INDEX_C),
            axiClk         => clk,
            axiRst         => rst,
            vPIn           => vPIn,
            vNIn           => vNIn);
      --------------------------
      -- AXI-Lite: SYSMON Module
      --------------------------
      U_AxiLiteEmpty : entity work.AxiLiteEmpty
         generic map (
            TPD_G            => TPD_G,
            AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
         port map (
            axiClk         => clk,
            axiClkRst      => rst,
            axiReadMaster  => mAxilReadMasters(SYS_MON_INDEX_C),
            axiReadSlave   => mAxilReadSlaves(SYS_MON_INDEX_C),
            axiWriteMaster => mAxilWriteMasters(SYS_MON_INDEX_C),
            axiWriteSlave  => mAxilWriteSlaves(SYS_MON_INDEX_C));

   end generate;

   GEN_ULTRA_SCALE : if (XIL_DEVICE_G = "ULTRASCALE") generate
      ------------------------
      -- AXI-Lite: XADC Module
      ------------------------
      U_AxiLiteEmpty : entity work.AxiLiteEmpty
         generic map (
            TPD_G            => TPD_G,
            AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
         port map (
            axiClk         => clk,
            axiClkRst      => rst,
            axiReadMaster  => mAxilReadMasters(XADC_INDEX_C),
            axiReadSlave   => mAxilReadSlaves(XADC_INDEX_C),
            axiWriteMaster => mAxilWriteMasters(XADC_INDEX_C),
            axiWriteSlave  => mAxilWriteSlaves(XADC_INDEX_C));
      --------------------------
      -- AXI-Lite: SYSMON Module
      --------------------------
      U_SysMon : entity work.SystemManagementWrapper
         generic map (
            TPD_G => TPD_G)
         port map (
            axiReadMaster  => mAxilReadMasters(SYS_MON_INDEX_C),
            axiReadSlave   => mAxilReadSlaves(SYS_MON_INDEX_C),
            axiWriteMaster => mAxilWriteMasters(SYS_MON_INDEX_C),
            axiWriteSlave  => mAxilWriteSlaves(SYS_MON_INDEX_C),
            axiClk         => clk,
            axiRst         => rst,
            vPIn           => vPIn,
            vNIn           => vNIn);
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
         gtRxControl         => timingRxControl,
         gtRxStatus          => timingRxStatus,
         gtTxReset           => open, -- not useful; if the TX is reset the TPGMini regs dont' work
         gtLoopback          => timingLoopbackSel,

         timingPhy           => timingTxPhy,
         timingClkSel        => timingClkSel,

         appTimingClk        => appTimingCLk,
         appTimingRst        => appTimingRst,
         appTimingBus        => timingBus,
         appTimingMode       => appTimingMode,

         exptBus             => exptBus,

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
         exptBus             => exptBus,
         -- Trigger and Sync Port
         trigOut             => appTimingTrig, -- out slv(11 downto 0);
         evrModeSel          => appTimingMode
      );

   P_TIMING_PHY : process( timingTxPhy, dbgi(0), timingTxRstAsync ) is
      variable v : TimingPhyType;
   begin
      v                  := timingTxPhy;
      v.control.pllReset := dbgi(0) or timingTxRstAsync;

      timingTxPhyLoc     <= v;
   end process P_TIMING_PHY;

   GEN_TIMING_GTH: if (GEN_TIMING_GTH_G) generate

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

   U_TimingGTH : entity work.TimingGthCoreWrapper
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

         gtRefClk         => timingRefClk,
         gtRefClkDiv2     => timingRefClkDiv2,

         gtRxP            => timingRxP,
         gtRxN            => timingRxN,
         gtTxP            => timingTxP,
         gtTxN            => timingTxN,

         rxControl        => timingRxControl,
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

      U_TimingClkSwitcher : entity work.TimingClkSwitcher
         generic map (
            TPD_G                  => TPD_G,
            SI570_AXIL_BASE_ADDR_G => SI570_AXIL_BASE_ADDR_C,
            TCASW_AXIL_BASE_ADDR_G => TCASW_AXIL_BASE_ADDR_C,
            AXIL_FREQ_G            => AXIL_CLK_FRQ_G
         )
         port map (
            axilClk                => clk,
            axilRst                => rst,

            clkSel                 => timingClkSel, -- timingClkSel already in AXIL domain

            txRst                  => timingTxRstAsync,

            mAxilReadMaster        => mAxilReadMaster,
            mAxilReadSlave         => mAxilReadSlave,
            mAxilWriteMaster       => mAxilWriteMaster,
            mAxilWriteSlave        => mAxilWriteSlave,

            sAxilReadMaster        => mAxilReadMasters (TCLKSWI_INDEX_C),
            sAxilReadSlave         => mAxilReadSlaves  (TCLKSWI_INDEX_C),
            sAxilWriteMaster       => mAxilWriteMasters(TCLKSWI_INDEX_C),
            sAxilWriteSlave        => mAxilWriteSlaves (TCLKSWI_INDEX_C)
          );

   end generate;

   NO_GEN_TIMING_GTH : if (not GEN_TIMING_GTH_G) generate
   signal timingClkLcls1 : sl;
   signal timingClkLcls2 : sl;
   signal timingRstLcls1 : sl;
   signal timingRstLcls2 : sl;
   begin

   U_SimTimingClock : entity work.ClockManagerUltraScale
      generic map (
         NUM_CLOCKS_G       => 2,
         CLKIN_PERIOD_G     => 8.0, -- 125MHz
         DIVCLK_DIVIDE_G    => 7,
         CLKFBOUT_MULT_F_G  => 41.625,

         CLKOUT0_DIVIDE_F_G => 6.250, -- ~119MHz
         CLKOUT1_DIVIDE_G   => 4      -- ~1300/7MHz
      )
      port map (
         clkIn              => clk,
         rstIn              => rst,

         clkOut(0)          => timingClkLcls1,
         clkOut(1)          => timingClkLcls2,

         rstOut(0)          => timingRstLcls1,
         rstOut(1)          => timingRstLcls2
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

   dbg(1)                   <= timingTxUsrClk;
   dbg(0)                   <= timingTxUsrRst;

   recTimingClk             <= timingRecClk;
   recTimingRst             <= timingRecRst;
   appTimingBus             <= timingBus;

   bsaWriteMaster                 <= mAxilWriteMasters(BSA_INDEX_C);
   mAxilWriteSlaves (BSA_INDEX_C) <= bsaWriteSlave;
   bsaReadMaster                  <= mAxilReadMasters (BSA_INDEX_C);
   mAxilReadSlaves  (BSA_INDEX_C) <= bsaReadSlave;

   appWriteMaster                 <= mAxilWriteMasters(APP_INDEX_C);
   mAxilWriteSlaves (APP_INDEX_C) <= appWriteSlave;
   appReadMaster                  <= mAxilReadMasters (APP_INDEX_C);
   mAxilReadSlaves  (APP_INDEX_C) <= appReadSlave;

end mapping;
