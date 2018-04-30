-------------------------------------------------------------------------------
-- File       : AppCore.vhd
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

entity AppCore is
   generic (
      TPD_G            : time             := 1 ns;
      BUILD_INFO_G     : BuildInfoType;
      XIL_DEVICE_G     : string           := "7SERIES";
      APP_TYPE_G       : string           := "ETH";
      AXIS_SIZE_G      : positive         := 1;
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_DECERR_C;
      MAC_ADDR_G       : slv(47 downto 0) := x"010300564400";  -- 00:44:56:00:03:01 (ETH only)
      IP_ADDR_G        : slv(31 downto 0) := x"0A02A8C0";  -- 192.168.2.10 (ETH only)
      DHCP_G           : boolean          := true;
      JUMBO_G          : boolean          := false;
      APP_STRM_CFG_G   : AxiStreamConfigType := ssiAxiStreamConfig(4);
      AXIL_CLK_FRQ_G   : real             := 156.25E6;
      DISABLE_BSA_G    : boolean          := false
   );
   port (
      -- Clock and Reset
      clk             : in  sl;
      rst             : in  sl;
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
end AppCore;

architecture mapping of AppCore is

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

   signal axilReadMaster    : AxiLiteReadMasterType;
   signal axilReadSlave     : AxiLiteReadSlaveType;
   signal axilWriteMaster   : AxiLiteWriteMasterType;
   signal axilWriteSlave    : AxiLiteWriteSlaveType;

   signal bsaReadMaster     : AxiLiteReadMasterType;
   signal bsaReadSlave      : AxiLiteReadSlaveType;
   signal bsaWriteMaster    : AxiLiteWriteMasterType;
   signal bsaWriteSlave     : AxiLiteWriteSlaveType;

   signal ibTimingEthMaster : AxiStreamMasterType;
   signal ibTimingEthSlave  : AxiStreamSlaveType;
   signal obTimingEthMaster : AxiStreamMasterType;
   signal obTimingEthSlave  : AxiStreamSlaveType;

   signal timingClk         : sl;
   signal timingRst         : sl;

   signal rssiIbMasters     : AxiStreamMasterArray(RSSI_SIZE_C - 1 downto 0);
   signal rssiIbSlaves      : AxiStreamSlaveArray (RSSI_SIZE_C - 1 downto 0);
   signal rssiObMasters     : AxiStreamMasterArray(RSSI_SIZE_C - 1 downto 0);
   signal rssiObSlaves      : AxiStreamSlaveArray (RSSI_SIZE_C - 1 downto 0);

   signal waveformMasters   : WaveformMasterArrayType := WAVEFORM_MASTER_ARRAY_INIT_C;
   signal waveformSlaves    : WaveformSlaveArrayType;

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
            clk             => clk,
            rst             => rst,
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
            clk                  => clk,

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

   -------------------
   -- AXI-Lite Modules
   -------------------
   U_Reg : entity work.AppReg
      generic map (
         TPD_G             => TPD_G,
         BUILD_INFO_G      => BUILD_INFO_G,
         XIL_DEVICE_G      => XIL_DEVICE_G,
         AXI_ERROR_RESP_G  => AXI_ERROR_RESP_G,
         AXIL_CLK_FRQ_G    => AXIL_CLK_FRQ_G)
      port map (
         -- Clock and Reset
         clk               => clk,
         rst               => rst,
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
         appTimingTrig     => open,
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
            axilClk              => clk,
            axilRst              => rst,
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

         U_AxilBsaEmpty : entity work.AxiLiteEmpty
            generic map (
               TPD_G             => TPD_G,
               AXI_ERROR_RESP_G  => AXI_RESP_OK_C
            )
            port map (
               axiClk            => clk,
               axiClkRst         => rst,
               axiReadMaster     => bsaReadMaster,
               axiReadSlave      => bsaReadSlave,
               axiWriteMaster    => bsaWriteMaster,
               axiWriteSlave     => bsaWriteSlave
            );
      end generate;

      rssiIbMasters(4) <= appTxMaster;
      appTxSlave       <= rssiIbSlaves (4);
      appRxMaster      <= rssiObMasters(4);
      rssiObSlaves(4)  <= appRxSlave;
      
         
      appTimingClk <= timingClk;
      appTimingRst <= timingRst;

end mapping;
