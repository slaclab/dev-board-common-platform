-------------------------------------------------------------------------------
-- File       : SystemManagementWrapper.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-01-30
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

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;

entity SystemManagementWrapper is
   generic (
      TPD_G : time := 1 ns);
   port (
      axiClk         : in  sl;
      axiRst         : in  sl;
      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType;
      tempOut        : out slv(9 downto 0);
      v0PIn          : in  sl;
      v0NIn          : in  sl;
      v2PIn          : in  sl;
      v2NIn          : in  sl;
      v8PIn          : in  sl;
      v8NIn          : in  sl;
      vPIn           : in  sl;
      vNIn           : in  sl;
      alarmOut       : out sl;
      tempAlarmOut   : out sl;
      otOut          : out sl;
      muxAddrOut     : out slv(4 downto 0)
      );
end entity SystemManagementWrapper;

architecture mapping of SystemManagementWrapper is

   signal axiRstL : sl;

begin

   axiRstL <= not axiRst;

   SystemManagementCore_Inst : entity work.SystemManagementCore
      port map (
         s_axi_aclk    => axiClk,
         s_axi_aresetn => axiRstL,
         s_axi_awaddr  => axiWriteMaster.awaddr(12 downto 0),
         s_axi_awvalid => axiWriteMaster.awvalid,
         s_axi_awready => axiWriteSlave.awready,
         s_axi_wdata   => axiWriteMaster.wdata,
         s_axi_wstrb   => axiWriteMaster.wstrb,
         s_axi_wvalid  => axiWriteMaster.wvalid,
         s_axi_wready  => axiWriteSlave.wready,
         s_axi_bresp   => axiWriteSlave.bresp,
         s_axi_bvalid  => axiWriteSlave.bvalid,
         s_axi_bready  => axiWriteMaster.bready,
         s_axi_araddr  => axiReadMaster.araddr(12 downto 0),
         s_axi_arvalid => axiReadMaster.arvalid,
         s_axi_arready => axiReadSlave.arready,
         s_axi_rdata   => axiReadSlave.rdata,
         s_axi_rresp   => axiReadSlave.rresp,
         s_axi_rvalid  => axiReadSlave.rvalid,
         s_axi_rready  => axiReadMaster.rready,
         temp_out      => tempOut,
         ip2intc_irpt  => open,
         vauxp0        => v0PIn,
         vauxn0        => v0NIn,
         vauxp2        => v2PIn,
         vauxn2        => v2NIn,
         vauxp8        => v8PIn,
         vauxn8        => v8NIn,
         vp            => vPIn,
         vn            => vNIn,
         busy_out      => open,
         channel_out   => open,
         eoc_out       => open,
         eos_out       => open,
         ot_out        => otOut,
         vccaux_alarm_out     => open,
         vccint_alarm_out     => open,
         user_temp_alarm_out  => tempAlarmOut,
         vbram_alarm_out      => open,
         alarm_out            => alarmOut,
         muxaddr_out          => muxAddrOut);

end architecture mapping;
