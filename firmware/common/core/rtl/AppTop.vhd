-------------------------------------------------------------------------------
-- File       : AppTop.vhd
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

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.AxiLitePkg.all;
use work.AxiPkg.all;
use work.SsiPkg.all;
use work.AmcCarrierPkg.all;
use work.AppTopPkg.all;
use work.TimingPkg.all;
use work.Jesd204bPkg.all;

entity AppTop is
   generic (
      TPD_G            : time             := 1 ns;
      BUILD_INFO_G     : BuildInfoType;
      XIL_DEVICE_G     : string           := "7SERIES";
      APP_TYPE_G       : string           := "ETH";
      AXIS_SIZE_G      : positive         := 1;
      MAC_ADDR_G       : slv(47 downto 0) := x"010300564400";  -- 00:44:56:00:03:01 (ETH only)
      IP_ADDR_G        : slv(31 downto 0) := x"0A02A8C0";  -- 192.168.2.10 (ETH only)
      DHCP_G           : boolean          := true;
      JUMBO_G          : boolean          := false;
      APP_STRM_CFG_G   : AxiStreamConfigType := ssiAxiStreamConfig(4);
      AXIL_CLK_FRQ_G   : real             := 156.25E6;
      DISABLE_BSA_G    : boolean          := false;
      JESD_CLK_IDIV_G  : positive         := 5;           -- with AXIL_CLK_FRQ_G = 125*5/4 -> 125/4MHz
      JESD_CLK_MULT_G  : real             := 35.5;        -- 1109.375MHz
      JESD_CLK_ODIV_G  : positive         := 3;           -- 369.79MHz; divider for jesdClk2x
      USER_CLK_ODIV_G  : positive         := 9;           -- jesd2x / 3
      NUM_BAYS_G       : positive range 1 to 2 := 1;
      SIG_GEN_NUM_G        : NaturalArray (1 downto 0) := (others => 4); -- 0 = disabled
      SIG_GEN_ADDR_WIDTH_G : PositiveArray(1 downto 0) := (others => 9);
      SIG_GEN_LANE_MODE_G  : Slv7Array    (1 downto 0) := (others => "0000000"); -- 0: 32-bit, 1: 16-bit
      SIG_GEN_RAM_CLK_G    : Slv7Array    (1 downto 0) := (others => "0000000")  -- 0: jesd2x, 1: jesd1x
   );

   port (
      -- Clock and Reset
      axilClk         : in  sl;
      axilRst         : in  sl;
      -- AXI Memory Interface
      axiClk          : in  sl;
      axiRst          : in  sl;
      axiWriteMaster  : out AxiWriteMasterType;
      axiWriteSlave   : in  AxiWriteSlaveType;
      axiReadMaster   : out AxiReadMasterType;
      axiReadSlave    : in  AxiReadSlaveType;
      -- AXIS interface
      txMasters       : out AxiStreamMasterArray(AXIS_SIZE_G-1 downto 0);
      txSlaves        : in  AxiStreamSlaveArray(AXIS_SIZE_G-1 downto 0);
      rxMasters       : in  AxiStreamMasterArray(AXIS_SIZE_G-1 downto 0);
      rxSlaves        : out AxiStreamSlaveArray(AXIS_SIZE_G-1 downto 0);
      rxCtrl          : out AxiStreamCtrlArray(AXIS_SIZE_G-1 downto 0);
      -- App Stream Interface
      appTxMaster     : in  AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      appTxSlave      : out AxiStreamSlaveType;
      appRxMaster     : out AxiStreamMasterType;
      appRxSlave      : in  AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;
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
      appTimingClk    : out sl;
      appTimingRst    : out sl;
      -- BSA Diagnostic
      diagnosticClk   : in  sl := '0';
      diagnosticRst   : in  sl := '0';
      diagnosticBus   : in  DiagnosticBusType := DIAGNOSTIC_BUS_INIT_C;

      dbg             : out slv(1 downto 0);
      dbgi            : in  slv(1 downto 0) := (others => '0')
      );
end AppTop;

architecture mapping of AppTop is

   constant RSSI_SIZE_C     : positive := 5;
   constant RSSI_STRM_CFG_C : AxiStreamConfigArray(RSSI_SIZE_C - 1 downto 0) := (
      4      => APP_STRM_CFG_G,
      others => ETH_AXIS_CONFIG_C
   );

   constant RSSI_ROUTES_C   : Slv8Array(RSSI_SIZE_C - 1 downto 0) := (
      0 => x"04",
      1 => x"02",
      2 => x"03",
      3 => "10------",
      4 => "11------"
   );

   constant N_AXIL_MASTERS_C: natural := 5;
   
   constant CORE_INDEX_C    : natural := 0;
   constant DAQMUX0_INDEX_C : natural := 1;
   constant DAQMUX1_INDEX_C : natural := 2;
   constant SIGGEN0_INDEX_C : natural := 3;
   constant SIGGEN1_INDEX_C : natural := 4;

   constant AXIL_CONFIG_C   : AxiLiteCrossbarMasterConfigArray(N_AXIL_MASTERS_C - 1 downto 0) :=
      genAxiLiteConfig(N_AXIL_MASTERS_C, x"80000000", 31, 28);

   signal axilReadMasters   : AxiLiteReadMasterArray (N_AXIL_MASTERS_C - 1 downto 0);
   signal axilReadSlaves    : AxiLiteReadSlaveArray  (N_AXIL_MASTERS_C - 1 downto 0) := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);
   signal axilWriteMasters  : AxiLiteWriteMasterArray(N_AXIL_MASTERS_C - 1 downto 0);
   signal axilWriteSlaves   : AxiLiteWriteSlaveArray (N_AXIL_MASTERS_C - 1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

   signal axilReadMaster    : AxiLiteReadMasterType;
   signal axilReadSlave     : AxiLiteReadSlaveType;
   signal axilWriteMaster   : AxiLiteWriteMasterType;
   signal axilWriteSlave    : AxiLiteWriteSlaveType;

   signal bsaReadMaster     : AxiLiteReadMasterType;
   signal bsaReadSlave      : AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
   signal bsaWriteMaster    : AxiLiteWriteMasterType;
   signal bsaWriteSlave     : AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;

   signal appReadMaster     : AxiLiteReadMasterType;
   signal appReadSlave      : AxiLiteReadSlaveType;
   signal appWriteMaster    : AxiLiteWriteMasterType;
   signal appWriteSlave     : AxiLiteWriteSlaveType;

   signal ibTimingEthMaster : AxiStreamMasterType;
   signal ibTimingEthSlave  : AxiStreamSlaveType;
   signal obTimingEthMaster : AxiStreamMasterType;
   signal obTimingEthSlave  : AxiStreamSlaveType;

   signal timingClk         : sl;
   signal timingRst         : sl;

   signal timingTrig        : TimingTrigType;

   signal rssiIbMasters     : AxiStreamMasterArray(RSSI_SIZE_C - 1 downto 0);
   signal rssiIbSlaves      : AxiStreamSlaveArray (RSSI_SIZE_C - 1 downto 0);
   signal rssiObMasters     : AxiStreamMasterArray(RSSI_SIZE_C - 1 downto 0);
   signal rssiObSlaves      : AxiStreamSlaveArray (RSSI_SIZE_C - 1 downto 0);

   signal waveformMasters   : WaveformMasterArrayType := WAVEFORM_MASTER_ARRAY_INIT_C;
   signal waveformSlaves    : WaveformSlaveArrayType;

   signal jesdClk           : sl;
   signal jesdRst           : sl;
   signal jesdClk2x         : sl;
   signal jesdRst2x         : sl;
   signal userClk           : sl;
   signal userRst           : sl;

   signal trigCascBay       : slv(NUM_BAYS_G     downto 0);
   signal armCascBay        : slv(NUM_BAYS_G     downto 0);
   signal trigHw            : slv(NUM_BAYS_G - 1 downto 0);
   signal freezeHw          : slv(NUM_BAYS_G - 1 downto 0);

   signal adcValids         : Slv7Array(NUM_BAYS_G - 1 downto 0) := (others => (others => '0' ) );
   signal adcValues         : sampleDataVectorArray(NUM_BAYS_G - 1 downto 0, 6 downto 0) := 
      (others => (others => (others => '0')));
   signal dacValids         : Slv7Array(NUM_BAYS_G - 1 downto 0) := (others => (others => '0' ) );
   signal dacValues         : sampleDataVectorArray(NUM_BAYS_G - 1 downto 0, 6 downto 0) :=
         (others => (others => (others => '0')));

   signal debugValids       : Slv4Array(NUM_BAYS_G - 1 downto 0) := (others => (others => '0' ) );
   signal debugValues       : sampleDataVectorArray(NUM_BAYS_G - 1 downto 0, 3 downto 0) :=
         (others => (others => (others => '0')));

   signal dataValids        : Slv18Array(NUM_BAYS_G - 1 downto 0) := (others => (others => '0' ) );
   signal linkReady         : Slv18Array(NUM_BAYS_G - 1 downto 0) := (others => (others => '1' ) );

   signal dacSigCtrl        : DacSigCtrlArray(NUM_BAYS_G - 1 downto 0) := (others => DAC_SIG_CTRL_INIT_C);
   signal dacSigStatus      : DacSigStatusArray(NUM_BAYS_G - 1 downto 0);
   signal dacSigValids      : Slv7Array(NUM_BAYS_G - 1 downto 0) := (others => (others => '0' ) );
   signal dacSigValues      : sampleDataVectorArray(NUM_BAYS_G - 1 downto 0, 6 downto 0) :=
            (others => (others => (others => '0')));

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

   GEN_ETH : if (APP_TYPE_G = "ETH") generate
      --------------------------
      -- UDP Port Mapping Module
      --------------------------
      U_EthPortMapping : entity work.EthPortMapping
         generic map (
            TPD_G           => TPD_G,
            MAC_ADDR_G      => MAC_ADDR_G,
            IP_ADDR_G       => IP_ADDR_G,
            DHCP_G          => DHCP_G,
            JUMBO_G         => JUMBO_G,
            RSSI_SIZE_G     => RSSI_SIZE_C,
            RSSI_STRM_CFG_G => RSSI_STRM_CFG_C,
            RSSI_ROUTES_G   => RSSI_ROUTES_C,
            UDP_SRV_SIZE_G  => 1,
            UDP_SRV_PORTS_G => (0 => 8197)
         )
         port map (
            -- Clock and Reset
            clk             => axilClk,
            rst             => axilRst,
            -- AXIS interface
            txMaster        => txMasters(0),
            txSlave         => txSlaves(0),
            rxMaster        => rxMasters(0),
            rxSlave         => rxSlaves(0),
            rxCtrl          => rxCtrl(0),
            -- RSSI Interface
            rssiIbMasters   => rssiIbMasters,
            rssiIbSlaves    => rssiIbSlaves,
            rssiObMasters   => rssiObMasters,
            rssiObSlaves    => rssiObSlaves,
            -- UDP Interface
            udpIbMasters(0) => obTimingEthMaster,
            udpIbSlaves(0)  => obTimingEthSlave,
            udpObMasters(0) => ibTimingEthMaster,
            udpObSlaves(0)  => ibTimingEthSlave,
            -- AXI-Lite interface
            axilWriteMaster => axilWriteMaster,
            axilWriteSlave  => axilWriteSlave,
            axilReadMaster  => axilReadMaster,
            axilReadSlave   => axilReadSlave
         );

      Ila_BsaStream : component Ila_256
         port map (
            clk                  => axilClk,

            probe0(63 downto  0) => rssiObMasters(0).tData (63 downto 0),

            probe1( 7 downto  0) => rssiObMasters(0).tStrb ( 7 downto 0),
            probe1(15 downto  8) => rssiObMasters(0).tKeep ( 7 downto 0),
            probe1(23 downto 16) => rssiObMasters(0).tDest ( 7 downto 0),
            probe1(31 downto 24) => rssiObMasters(0).tId   ( 7 downto 0),
            probe1(60 downto 32) => rssiObMasters(0).tUser (28 downto 0),

            probe1(61          ) => rssiObMasters(0).tLast,
            probe1(62          ) => rssiObMasters(0).tValid,
            probe1(63          ) => rssiObSlaves (0).tReady,

            probe2(63 downto  0) => rssiIbMasters(0).tData (63 downto 0),

            probe3( 7 downto  0) => rssiIbMasters(0).tStrb ( 7 downto 0),
            probe3(15 downto  8) => rssiIbMasters(0).tKeep ( 7 downto 0),
            probe3(23 downto 16) => rssiIbMasters(0).tDest ( 7 downto 0),
            probe3(31 downto 24) => rssiIbMasters(0).tId   ( 7 downto 0),
            probe3(60 downto 32) => rssiIbMasters(0).tUser (28 downto 0),

            probe3(61          ) => rssiIbMasters(0).tLast,
            probe3(62          ) => rssiIbMasters(0).tValid,
            probe3(63          ) => rssiIbSlaves (0).tReady
         );

   end generate;

   U_SimJesdClock : entity work.ClockManagerUltraScale
      generic map (
         NUM_CLOCKS_G       => 3,
         CLKIN_PERIOD_G     => (1.0E9/AXIL_CLK_FRQ_G),
         DIVCLK_DIVIDE_G    => JESD_CLK_IDIV_G,
         CLKFBOUT_MULT_F_G  => JESD_CLK_MULT_G,

         CLKOUT0_DIVIDE_G   => JESD_CLK_ODIV_G,
         CLKOUT1_DIVIDE_G   => (2*JESD_CLK_ODIV_G),
         CLKOUT2_DIVIDE_G   => USER_CLK_ODIV_G
      )
      port map (
         clkIn              => axilClk,
         rstIn              => axilRst,

         clkOut(2)          => userClk,
         clkOut(1)          => jesdClk,
         clkOut(0)          => jesdClk2x,

         rstOut(2)          => userRst,
         rstOut(1)          => jesdRst,
         rstOut(0)          => jesdRst2x
      );

   -- AXI-Lite Modules
   -------------------

   U_Xbar : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => N_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => AXIL_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => appWriteMaster,
         sAxiWriteSlaves(0)  => appWriteSlave,
         sAxiReadMasters(0)  => appReadMaster,
         sAxiReadSlaves(0)   => appReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   axilWriteSlaves( CORE_INDEX_C ) <= AXI_LITE_WRITE_SLAVE_INIT_C;
   axilReadSlaves ( CORE_INDEX_C ) <= AXI_LITE_READ_SLAVE_INIT_C;


   U_Reg : entity work.AppReg
      generic map (
         TPD_G             => TPD_G,
         BUILD_INFO_G      => BUILD_INFO_G,
         XIL_DEVICE_G      => XIL_DEVICE_G,
         AXIL_CLK_FRQ_G    => AXIL_CLK_FRQ_G)
      port map (
         -- Clock and Reset
         clk               => axilClk,
         rst               => axilRst,
         -- AXI-Lite interface
         axilWriteMaster   => axilWriteMaster,
         axilWriteSlave    => axilWriteSlave,
         axilReadMaster    => axilReadMaster,
         axilReadSlave     => axilReadSlave,
         
         -- AXI-Lite devices
         bsaReadMaster     => bsaReadMaster,
         bsaReadSlave      => bsaReadSlave,
         bsaWriteMaster    => bsaWriteMaster,
         bsaWriteSlave     => bsaWriteSlave,

         appReadMaster     => appReadMaster,
         appReadSlave      => appReadSlave,
         appWriteMaster    => appWriteMaster,
         appWriteSlave     => appWriteSlave,

         obTimingEthMaster => obTimingEthMaster,
         obTimingEthSlave  => obTimingEthSlave,
         ibTimingEthMaster => ibTimingEthMaster,
         ibTimingEthSlave  => ibTimingEthSlave,

         -- ADC Ports
         vPIn              => vPIn,
         vNIn              => vNIn,
         -- IIC Port
         iicScl            => iicScl,
         iicSda            => iicSda,
         -- Timing
         timingRefClkP     => timingRefClkP,
         timingRefClkN     => timingRefClkN,
         timingRxP         => timingRxP,
         timingRxN         => timingRxN,
         timingTxP         => timingTxP,
         timingTxN         => timingTxN,

         recTimingClk      => timingClk,
         recTimingRst      => timingRst,

         appTimingClk      => timingClk,
         appTimingRst      => timingRst,

         appTimingBus      => open,
         appTimingTrig     => timingTrig,
         dbg               => dbg,
         dbgi              => dbgi
         );

      U_BSA : entity work.AmcCarrierBsa
         generic map (
            TPD_G          => TPD_G,
            FSBL_G         => false,
            DISABLE_BSA_G  => DISABLE_BSA_G,
            DISABLE_BLD_G  => true
         )
         port map (
            -- AXI-Lite Interface (axilClk domain)
            axilClk              => axilClk,
            axilRst              => axilRst,
            axilReadMaster       => bsaReadMaster,
            axilReadSlave        => bsaReadSlave,
            axilWriteMaster      => bsaWriteMaster,
            axilWriteSlave       => bsaWriteSlave,
            -- AXI4 Interface (axiClk domain)
            axiClk               => axiClk,
            axiRst               => axiRst,
            axiWriteMaster       => axiWriteMaster,
            axiWriteSlave        => axiWriteSlave,
            axiReadMaster        => axiReadMaster,
            axiReadSlave         => axiReadSlave,

            -- Ethernet Interface (axilClk domain)
            obBsaMasters         => rssiIbMasters(3 downto 0),
            obBsaSlaves          => rssiIbSlaves (3 downto 0),
            ibBsaMasters         => rssiObMasters(3 downto 0),
            ibBsaSlaves          => rssiObSlaves (3 downto 0),
            ----------------------
            -- Top Level Interface
            ----------------------         
            -- Diagnostic Interface
            diagnosticClk        => diagnosticClk,
            diagnosticRst        => diagnosticRst,
            diagnosticBus        => diagnosticBus,
            -- Waveform interface (axiClk domain)
            waveformClk          => axiClk,
            waveformRst          => axiRst,
            obAppWaveformMasters => waveformMasters,
            obAppWaveformSlaves  => waveformSlaves
         );
   

      NO_GEN_BSA : if ( DISABLE_BSA_G ) generate
         rssiObSlaves (3 downto 0) <= (others => AXI_STREAM_SLAVE_FORCE_C);
         rssiIbMasters(3 downto 0) <= (others => AXI_STREAM_MASTER_INIT_C);

         axiWriteMaster            <= AXI_WRITE_MASTER_INIT_C;
      end generate;

      trigCascBay(NUM_BAYS_G) <= trigCascBay(0);
      armCascBay (NUM_BAYS_G) <= armCascBay(0);

      GEN_BAY : for i in NUM_BAYS_G - 1 downto 0 generate

      U_DaqMuxV2 : entity work.DaqMuxV2
         generic map (
            TPD_G                  => TPD_G,
            DECIMATOR_EN_G         => true,
            WAVEFORM_TDATA_BYTES_G => 4,
            BAY_INDEX_G            => ite((i = 0), '0', '1'),
            N_DATA_IN_G            => 18,
            N_DATA_OUT_G           => 4)
         port map (
            -- Clocks and Resets
            axiClk              => axilClk,
            axiRst              => axilRst,
            devClk_i            => jesdClk,
            devRst_i            => jesdRst,
            -- External DAQ trigger input
            trigHw_i            => trigHw(i),
            -- Cascaded Sw trigger for external connection between modules
            trigCasc_i          => trigCascBay(i+1),
            trigCasc_o          => trigCascBay(i),
            -- Cascaded Arm trigger for external connection between modules 
            armCasc_i           => armCascBay(i+1),
            armCasc_o           => armCascBay(i),
            -- Freeze buffers
            freezeHw_i          => freezeHw(i),
            -- Time-stamp and bsa (if enabled it will be added to start of data)
            timeStamp_i         => timingTrig.timeStamp,
            bsa_i               => timingTrig.bsa,
            dmod_i              => timingTrig.dmod,
            -- AXI-Lite Register Interface
            axilReadMaster      => axilReadMasters(DAQMUX0_INDEX_C+i),
            axilReadSlave       => axilReadSlaves(DAQMUX0_INDEX_C+i),
            axilWriteMaster     => axilWriteMasters(DAQMUX0_INDEX_C+i),
            axilWriteSlave      => axilWriteSlaves(DAQMUX0_INDEX_C+i),
            -- Sample data input 
            sampleDataArr_i(0)  => adcValues(i, 0),
            sampleDataArr_i(1)  => adcValues(i, 1),
            sampleDataArr_i(2)  => adcValues(i, 2),
            sampleDataArr_i(3)  => adcValues(i, 3),
            sampleDataArr_i(4)  => adcValues(i, 4),
            sampleDataArr_i(5)  => adcValues(i, 5),
            sampleDataArr_i(6)  => adcValues(i, 6),
            sampleDataArr_i(7)  => dacValues(i, 0),
            sampleDataArr_i(8)  => dacValues(i, 1),
            sampleDataArr_i(9)  => dacValues(i, 2),
            sampleDataArr_i(10) => dacValues(i, 3),
            sampleDataArr_i(11) => dacValues(i, 4),
            sampleDataArr_i(12) => dacValues(i, 5),
            sampleDataArr_i(13) => dacValues(i, 6),
            sampleDataArr_i(14) => debugValues(i, 0),
            sampleDataArr_i(15) => debugValues(i, 1),
            sampleDataArr_i(16) => debugValues(i, 2),
            sampleDataArr_i(17) => debugValues(i, 3),
            sampleValidVec_i    => dataValids(i),
            linkReadyVec_i      => linkReady(i),
            -- Output AXI Streaming Interface (Has to be synced with waveform clk)
            wfClk_i             => axiClk,
            wfRst_i             => axiRst,
            rxAxisMasterArr_o   => waveformMasters(i),
            rxAxisSlaveArr_i(0) => waveformSlaves(i)(0).slave,
            rxAxisSlaveArr_i(1) => waveformSlaves(i)(1).slave,
            rxAxisSlaveArr_i(2) => waveformSlaves(i)(2).slave,
            rxAxisSlaveArr_i(3) => waveformSlaves(i)(3).slave,
            rxAxisCtrlArr_i(0)  => waveformSlaves(i)(0).ctrl,
            rxAxisCtrlArr_i(1)  => waveformSlaves(i)(1).ctrl,
            rxAxisCtrlArr_i(2)  => waveformSlaves(i)(2).ctrl,
            rxAxisCtrlArr_i(3)  => waveformSlaves(i)(3).ctrl
      );

      dataValids(i) <= debugValids(i) & dacValids(i) & adcValids(i);
      linkReady(i)  <= x"F" & dacValids(i) & adcValids(i);

      U_DacSigGen : entity work.DacSigGen
         generic map (
            TPD_G                => TPD_G,
            AXI_BASE_ADDR_G      => AXIL_CONFIG_C(SIGGEN0_INDEX_C+i).baseAddr,
            SIG_GEN_SIZE_G       => SIG_GEN_NUM_G(i),
            SIG_GEN_ADDR_WIDTH_G => SIG_GEN_ADDR_WIDTH_G(i),
            SIG_GEN_LANE_MODE_G  => SIG_GEN_LANE_MODE_G(i),
            SIG_GEN_RAM_CLK_G    => SIG_GEN_RAM_CLK_G(i))
         port map (
            -- DAC Signal Generator Interface
            jesdClk         => jesdClk,
            jesdRst         => jesdRst,
            jesdClk2x       => jesdClk2x,
            jesdRst2x       => jesdRst2x,
            dacSigCtrl      => dacSigCtrl(i),
            dacSigStatus    => dacSigStatus(i),
            dacSigValids    => dacSigValids(i),
            dacSigValues(0) => dacSigValues(i, 0),
            dacSigValues(1) => dacSigValues(i, 1),
            dacSigValues(2) => dacSigValues(i, 2),
            dacSigValues(3) => dacSigValues(i, 3),
            dacSigValues(4) => dacSigValues(i, 4),
            dacSigValues(5) => dacSigValues(i, 5),
            dacSigValues(6) => dacSigValues(i, 6),
            -- AXI-Lite Interface
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => axilReadMasters(SIGGEN0_INDEX_C+i),
            axilReadSlave   => axilReadSlaves(SIGGEN0_INDEX_C+i),
            axilWriteMaster => axilWriteMasters(SIGGEN0_INDEX_C+i),
            axilWriteSlave  => axilWriteSlaves(SIGGEN0_INDEX_C+i)
         );

      end generate;

      GEN_NO_BAY1 : if (NUM_BAYS_G = 1) generate
         waveformMasters(1) <= WAVEFORM_MASTER_ARRAY_INIT_C(1);
      end generate;

      rssiIbMasters(4) <= appTxMaster;
      appTxSlave       <= rssiIbSlaves (4);
      appRxMaster      <= rssiObMasters(4);
      rssiObSlaves(4)  <= appRxSlave;
      
         
      appTimingClk <= timingClk;
      appTimingRst <= timingRst;

end mapping;
