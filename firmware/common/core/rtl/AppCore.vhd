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
use work.SsiPkg.all;

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
      AXIL_CLK_FRQ_G   : real             := 156.25E6);
   port (
      -- Clock and Reset
      clk             : in  sl;
      rst             : in  sl;
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
      dbg             : out slv(1 downto 0);
      dbgi            : in  slv(1 downto 0) := (others => '0')
      );
end AppCore;

architecture mapping of AppCore is

   signal axilReadMaster    : AxiLiteReadMasterType;
   signal axilReadSlave     : AxiLiteReadSlaveType;
   signal axilWriteMaster   : AxiLiteWriteMasterType;
   signal axilWriteSlave    : AxiLiteWriteSlaveType;

   signal ibTimingEthMaster : AxiStreamMasterType;
   signal ibTimingEthSlave  : AxiStreamSlaveType;
   signal obTimingEthMaster : AxiStreamMasterType;
   signal obTimingEthSlave  : AxiStreamSlaveType;

   signal timingClk         : sl;
   signal timingRst         : sl;

   constant RSSI_SIZE_C     : positive := 1;
   constant RSSI_STRM_CFG_C : AxiStreamConfigArray(RSSI_SIZE_C - 1 downto 0) := (
      0 => APP_STRM_CFG_G
   );

   constant RSSI_ROUTES_C   : Slv8Array(RSSI_SIZE_C - 1 downto 0) := (
      0 => x"04"
   );

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
            rssiIbMasters(0)=> appTxMaster,
            rssiIbSlaves(0) => appTxSlave,
            rssiObMasters(0)=> appRxMaster,
            rssiObSlaves(0) => appRxSlave,
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

   end generate;

   -------------------
   -- AXI-Lite Modules
   -------------------
   U_Reg : entity work.AppReg
      generic map (
         TPD_G            => TPD_G,
         BUILD_INFO_G     => BUILD_INFO_G,
         XIL_DEVICE_G     => XIL_DEVICE_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         AXIL_CLK_FRQ_G   => AXIL_CLK_FRQ_G)
      port map (
         -- Clock and Reset
         clk             => clk,
         rst             => rst,
         -- AXI-Lite interface
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,

         obTimingEthMaster => obTimingEthMaster,
         obTimingEthSlave  => obTimingEthSlave,
         ibTimingEthMaster => ibTimingEthMaster,
         ibTimingEthSlave  => ibTimingEthSlave,

         -- ADC Ports
         vPIn            => vPIn,
         vNIn            => vNIn,
         -- IIC Port
         iicScl          => iicScl,
         iicSda          => iicSda,
         -- Timing
         timingRefClkP   => timingRefClkP,
         timingRefClkN   => timingRefClkN,
         timingRxP       => timingRxP,
         timingRxN       => timingRxN,
         timingTxP       => timingTxP,
         timingTxN       => timingTxN,

         recTimingClk    => timingClk,
         recTimingRst    => timingRst,

         appTimingClk    => timingClk,
         appTimingRst    => timingRst,

         appTimingBus    => open,
         appTimingTrig   => open,
         dbg             => dbg,
         dbgi            => dbgi
         );
         
      appTimingClk <= timingClk;
      appTimingRst <= timingRst;

end mapping;
