-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AppCore.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-02-05
-- Last update: 2016-04-27
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

entity AppCore is
   generic (
      TPD_G            : time             := 1 ns;
      XIL_DEVICE_G     : string           := "7SERIES";
      APP_TYPE_G       : string           := "ETH";
      AXIS_SIZE_G      : positive         := 1;
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_DECERR_C;
      MAC_ADDR_G       : slv(47 downto 0) := x"010300564400";  -- 192.168.2.10 (ETH only)
      IP_ADDR_G        : slv(31 downto 0) := x"0A02A8C0");     -- 00:44:56:00:03:01 (ETH only)
   port (
      -- Clock and Reset
      clk       : in  sl;
      rst       : in  sl;
      -- AXIS interface
      txMasters : out AxiStreamMasterArray(AXIS_SIZE_G-1 downto 0);
      txSlaves  : in  AxiStreamSlaveArray(AXIS_SIZE_G-1 downto 0);
      rxMasters : in  AxiStreamMasterArray(AXIS_SIZE_G-1 downto 0);
      rxSlaves  : out AxiStreamSlaveArray(AXIS_SIZE_G-1 downto 0);
      rxCtrl    : out AxiStreamCtrlArray(AXIS_SIZE_G-1 downto 0);
      -- ADC Ports
      vPIn      : in  sl;
      vNIn      : in  sl);
end AppCore;

architecture mapping of AppCore is

   signal axilReadMaster  : AxiLiteReadMasterType;
   signal axilReadSlave   : AxiLiteReadSlaveType;
   signal axilWriteMaster : AxiLiteWriteMasterType;
   signal axilWriteSlave  : AxiLiteWriteSlaveType;

   signal pbrsTxMaster : AxiStreamMasterType;
   signal pbrsTxSlave  : AxiStreamSlaveType;
   signal pbrsRxMaster : AxiStreamMasterType;
   signal pbrsRxSlave  : AxiStreamSlaveType;

   signal mbTxMaster   : AxiStreamMasterType;
   signal mbTxSlave    : AxiStreamSlaveType;

begin

   GEN_ETH : if (APP_TYPE_G = "ETH") generate
      --------------------------
      -- UDP Port Mapping Module
      --------------------------
      U_EthPortMapping : entity work.EthPortMapping
         generic map (
            TPD_G      => TPD_G,
            MAC_ADDR_G => MAC_ADDR_G,
            IP_ADDR_G  => IP_ADDR_G)
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
            -- PBRS Interface
            pbrsTxMaster    => pbrsTxMaster,
            pbrsTxSlave     => pbrsTxSlave,
            pbrsRxMaster    => pbrsRxMaster,
            pbrsRxSlave     => pbrsRxSlave,
            -- AXI-Lite interface
            axilWriteMaster => axilWriteMaster,
            axilWriteSlave  => axilWriteSlave,
            axilReadMaster  => axilReadMaster,
            axilReadSlave   => axilReadSlave);  

      mbTxSlave  <= AXI_STREAM_SLAVE_FORCE_C;

   end generate;

   GEN_PGP : if (APP_TYPE_G = "PGP") generate
      ---------------------------------
      -- Virtual Channel Mapping Module
      ---------------------------------         
      U_PgpVcMapping : entity work.PgpVcMapping
         generic map (
            TPD_G => TPD_G)
         port map (
            -- Clock and Reset
            clk             => clk,
            rst             => rst,
            -- AXIS interface
            txMasters       => txMasters,
            txSlaves        => txSlaves,
            rxMasters       => rxMasters,
            rxSlaves        => rxSlaves,
            rxCtrl          => rxCtrl,
            -- PBRS Interface
            pbrsTxMaster    => pbrsTxMaster,
            pbrsTxSlave     => pbrsTxSlave,
            pbrsRxMaster    => pbrsRxMaster,
            pbrsRxSlave     => pbrsRxSlave,
            -- AXI-Lite interface
            axilWriteMaster => axilWriteMaster,
            axilWriteSlave  => axilWriteSlave,
            axilReadMaster  => axilReadMaster,
            axilReadSlave   => axilReadSlave,
            -- Microblaze stream
            mbTxMaster      => mbTxMaster,
            mbTxSlave       => mbTxSlave
         );      
   end generate;

   -------------------
   -- AXI-Lite Modules
   -------------------
   U_Reg : entity work.AppReg
      generic map (
         TPD_G            => TPD_G,
         XIL_DEVICE_G     => XIL_DEVICE_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
      port map (
         -- Clock and Reset
         clk             => clk,
         rst             => rst,
         -- AXI-Lite interface
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         -- PBRS Interface
         pbrsTxMaster    => pbrsTxMaster,
         pbrsTxSlave     => pbrsTxSlave,
         pbrsRxMaster    => pbrsRxMaster,
         pbrsRxSlave     => pbrsRxSlave,
         -- Microblaze stream
         mbTxMaster      => mbTxMaster,
         mbTxSlave       => mbTxSlave,
         -- ADC Ports
         vPIn            => vPIn,
         vNIn            => vNIn);    

end mapping;
