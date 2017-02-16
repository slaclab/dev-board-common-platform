-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : EthPortMapping.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-01-30
-- Last update: 2016-09-21
-- Platform   : 
-- Standard   : VHDL'93/02
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
use work.EthMacPkg.all;

entity EthPortMapping is
   generic (
      TPD_G      : time             := 1 ns;
      MAC_ADDR_G : slv(47 downto 0) := x"010300564400";  -- 192.168.2.10 (ETH only)
      IP_ADDR_G  : slv(31 downto 0) := x"0A02A8C0");     -- 00:44:56:00:03:01 (ETH only)      
   port (
      -- Clock and Reset
      clk             : in  sl;
      rst             : in  sl;
      -- ETH interface
      txMaster        : out AxiStreamMasterType;
      txSlave         : in  AxiStreamSlaveType;
      rxMaster        : in  AxiStreamMasterType;
      rxSlave         : out AxiStreamSlaveType;
      rxCtrl          : out AxiStreamCtrlType;
      -- PBRS Interface
      pbrsTxMaster    : in  AxiStreamMasterType;
      pbrsTxSlave     : out AxiStreamSlaveType;
      pbrsRxMaster    : out AxiStreamMasterType;
      pbrsRxSlave     : in  AxiStreamSlaveType;
      -- AXI-Lite Interface
      axilWriteMaster : out AxiLiteWriteMasterType;
      axilWriteSlave  : in  AxiLiteWriteSlaveType;
      axilReadMaster  : out AxiLiteReadMasterType;
      axilReadSlave   : in  AxiLiteReadSlaveType);
end EthPortMapping;

architecture mapping of EthPortMapping is

   constant NUM_SERVERS_C  : integer                                 := 2;
   constant PROTOCOL_C     : Slv8Array(0 downto 0)                   := (0 => UDP_C);
   constant SERVER_PORTS_C : PositiveArray(NUM_SERVERS_C-1 downto 0) := (0 => 8192, 1 => 8193);

   signal ibServerMasters : AxiStreamMasterArray(NUM_SERVERS_C-1 downto 0);
   signal ibServerSlaves  : AxiStreamSlaveArray(NUM_SERVERS_C-1 downto 0);
   signal obServerMasters : AxiStreamMasterArray(NUM_SERVERS_C-1 downto 0);
   signal obServerSlaves  : AxiStreamSlaveArray(NUM_SERVERS_C-1 downto 0);

   -- attribute dont_touch                    : string;
   -- attribute dont_touch of ibServerMasters : signal is "TRUE";
   -- attribute dont_touch of ibServerSlaves  : signal is "TRUE";
   -- attribute dont_touch of obServerMasters : signal is "TRUE";
   -- attribute dont_touch of obServerSlaves  : signal is "TRUE";

begin

   ----------------------
   -- IPv4/ARP/UDP Engine
   ----------------------
   U_UDP : entity work.UdpEngineWrapper
      generic map (
         -- Simulation Generics
         TPD_G          => TPD_G,
         -- UDP Server Generics
         SERVER_EN_G    => true,
         SERVER_SIZE_G  => NUM_SERVERS_C,
         SERVER_PORTS_G => SERVER_PORTS_C,
         -- UDP Client Generics
         CLIENT_EN_G    => false)
      port map (
         -- Local Configurations
         localMac        => MAC_ADDR_G,
         localIp         => IP_ADDR_G,
         -- Interface to Ethernet Media Access Controller (MAC)
         obMacMaster     => rxMaster,
         obMacSlave      => rxSlave,
         ibMacMaster     => txMaster,
         ibMacSlave      => txSlave,
         -- Interface to UDP Server engine(s)
         obServerMasters => obServerMasters,
         obServerSlaves  => obServerSlaves,
         ibServerMasters => ibServerMasters,
         ibServerSlaves  => ibServerSlaves,
         -- Clock and Reset
         clk             => clk,
         rst             => rst);

   ----------------------------
   -- AXI-Lite Master Interface 
   ----------------------------   
   U_SRPv0 : entity work.SrpV0AxiLite
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         EN_32BIT_ADDR_G     => true,
         BRAM_EN_G           => true,
         GEN_SYNC_FIFO_G     => true,
         AXI_STREAM_CONFIG_G => EMAC_AXIS_CONFIG_C)
      port map (
         -- Streaming Slave (Rx) Interface (sAxisClk domain) 
         sAxisClk            => clk,
         sAxisRst            => rst,
         sAxisMaster         => obServerMasters(0),
         sAxisSlave          => obServerSlaves(0),
         -- Streaming Master (Tx) Data Interface (mAxisClk domain)
         mAxisClk            => clk,
         mAxisRst            => rst,
         mAxisMaster         => ibServerMasters(0),
         mAxisSlave          => ibServerSlaves(0),
         -- AXI Lite Bus (axiLiteClk domain)
         axiLiteClk          => clk,
         axiLiteRst          => rst,
         mAxiLiteReadMaster  => axilReadMaster,
         mAxiLiteReadSlave   => axilReadSlave,
         mAxiLiteWriteMaster => axilWriteMaster,
         mAxiLiteWriteSlave  => axilWriteSlave);

   -- Mapping the 2nd UDP port as a loopback channel
   ibServerMasters(1) <= obServerMasters(1);
   obServerSlaves(1)  <= ibServerSlaves(1);

   -- Terminate Unused interfaces   
   rxCtrl       <= AXI_STREAM_CTRL_UNUSED_C;
   pbrsRxMaster <= AXI_STREAM_MASTER_INIT_C;
   pbrsTxSlave  <= AXI_STREAM_SLAVE_FORCE_C;
   
end mapping;
