-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierDdrMem.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2017-02-09
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 Common Carrier Core'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'LCLS2 Common Carrier Core', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcCarrierDdrMem is
   generic (
      TPD_G            : time            := 1 ns;
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C;
      SIM_SPEEDUP_G    : boolean         := false);
   port (
      -- AXI-Lite Interface
      axilClk         : in    sl;
      axilRst         : in    sl;
      axilReadMaster  : in    AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;
      memReady        : out   sl;
      memError        : out   sl;
      -- AXI4 Interface
      axiClk          : out   sl;
      axiRst          : out   sl;
      axiWriteMaster  : in    AxiWriteMasterType;
      axiWriteSlave   : out   AxiWriteSlaveType;
      axiReadMaster   : in    AxiReadMasterType;
      axiReadSlave    : out   AxiReadSlaveType;
      ----------------
      -- Core Ports --
      ----------------   
      -- DDR4 Ports
      refClk          : in    sl;
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
      c0_ddr4_alert_n : IN STD_LOGIC
   );

end AmcCarrierDdrMem;

architecture mapping of AmcCarrierDdrMem is

   constant AXI_NBYTES_C : natural := 64;

   constant AXI_CONFIG_C : AxiConfigType := (
      ADDR_WIDTH_C => 31,
      DATA_BYTES_C => AXI_NBYTES_C,
      ID_BITS_C    => 4,
      LEN_BITS_C   => 8);

   constant START_ADDR_C : slv(AXI_CONFIG_C.ADDR_WIDTH_C-1 downto 0) := (others => '0');
   constant STOP_ADDR_C  : slv(AXI_CONFIG_C.ADDR_WIDTH_C-1 downto 0) := (others => '1');
   

   COMPONENT ddr4_0
     PORT (
       c0_init_calib_complete : OUT STD_LOGIC;
       dbg_clk : OUT STD_LOGIC;
       c0_sys_clk_i : IN STD_LOGIC;
       dbg_bus : OUT STD_LOGIC_VECTOR(511 DOWNTO 0);
       c0_ddr4_adr : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
       c0_ddr4_ba : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
       c0_ddr4_cke : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
       c0_ddr4_cs_n : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
       c0_ddr4_dm_dbi_n : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
       c0_ddr4_dq : INOUT STD_LOGIC_VECTOR(63 DOWNTO 0);
       c0_ddr4_dqs_c : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
       c0_ddr4_dqs_t : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
       c0_ddr4_odt : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
       c0_ddr4_bg : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
       c0_ddr4_reset_n : OUT STD_LOGIC;
       c0_ddr4_act_n : OUT STD_LOGIC;
       c0_ddr4_ck_c : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
       c0_ddr4_ck_t : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
       c0_ddr4_ui_clk : OUT STD_LOGIC;
       c0_ddr4_ui_clk_sync_rst : OUT STD_LOGIC;
       c0_ddr4_aresetn : IN STD_LOGIC;
       c0_ddr4_s_axi_awid : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
       c0_ddr4_s_axi_awaddr : IN STD_LOGIC_VECTOR(30 DOWNTO 0);
       c0_ddr4_s_axi_awlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
       c0_ddr4_s_axi_awsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
       c0_ddr4_s_axi_awburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
       c0_ddr4_s_axi_awlock : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
       c0_ddr4_s_axi_awcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
       c0_ddr4_s_axi_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
       c0_ddr4_s_axi_awqos : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
       c0_ddr4_s_axi_awvalid : IN STD_LOGIC;
       c0_ddr4_s_axi_awready : OUT STD_LOGIC;
       c0_ddr4_s_axi_wdata : IN STD_LOGIC_VECTOR(8*AXI_NBYTES_C-1 DOWNTO 0);
       c0_ddr4_s_axi_wstrb : IN STD_LOGIC_VECTOR(AXI_NBYTES_C-1 DOWNTO 0);
       c0_ddr4_s_axi_wlast : IN STD_LOGIC;
       c0_ddr4_s_axi_wvalid : IN STD_LOGIC;
       c0_ddr4_s_axi_wready : OUT STD_LOGIC;
       c0_ddr4_s_axi_bready : IN STD_LOGIC;
       c0_ddr4_s_axi_bid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
       c0_ddr4_s_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
       c0_ddr4_s_axi_bvalid : OUT STD_LOGIC;
       c0_ddr4_s_axi_arid : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
       c0_ddr4_s_axi_araddr : IN STD_LOGIC_VECTOR(30 DOWNTO 0);
       c0_ddr4_s_axi_arlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
       c0_ddr4_s_axi_arsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
       c0_ddr4_s_axi_arburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
       c0_ddr4_s_axi_arlock : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
       c0_ddr4_s_axi_arcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
       c0_ddr4_s_axi_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
       c0_ddr4_s_axi_arqos : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
       c0_ddr4_s_axi_arvalid : IN STD_LOGIC;
       c0_ddr4_s_axi_arready : OUT STD_LOGIC;
       c0_ddr4_s_axi_rready : IN STD_LOGIC;
       c0_ddr4_s_axi_rlast : OUT STD_LOGIC;
       c0_ddr4_s_axi_rvalid : OUT STD_LOGIC;
       c0_ddr4_s_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
       c0_ddr4_s_axi_rid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
       c0_ddr4_s_axi_rdata : OUT STD_LOGIC_VECTOR(8*AXI_NBYTES_C-1 DOWNTO 0);
       sys_rst : IN STD_LOGIC
     );
   END COMPONENT;

   signal ddrWriteMaster : AxiWriteMasterType := AXI_WRITE_MASTER_INIT_C;
   signal ddrWriteSlave  : AxiWriteSlaveType  := AXI_WRITE_SLAVE_INIT_C;
   signal ddrReadMaster  : AxiReadMasterType  := AXI_READ_MASTER_INIT_C;
   signal ddrReadSlave   : AxiReadSlaveType   := AXI_READ_SLAVE_INIT_C;

   signal ddrClk     : sl;
   signal ddrRst     : sl;
   signal reset      : sl;
   signal sysRst     : sl;
   signal axiRstL    : sl;
   signal ddrCalDone : sl;
   signal done       : sl;
   signal coreRst    : slv(1 downto 0);

   attribute KEEP_HIERARCHY           : string;

   attribute dont_touch               : string;
   
   type RegType is record
      ddrPwrEn       : sl;
      ddrReset       : sl;
      memReady       : sl;
      memError       : sl;
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      ddrPwrEn       => '1',
      ddrReset       => '0',
      memReady       => '0',
      memError       => '0',
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal pg     : sl := '0';
   signal alertL : sl;

begin

   axiClk  <= ddrClk;
   axiRst  <= ddrRst;
   axiRstL <= not(ddrRst);

   U_ddrAlertL : IBUF
      port map (
         I => c0_ddr4_alert_n,
         O => alertL);

   reset   <= axilRst or r.ddrReset;

   U_RstSync : entity work.RstSync
      generic map (
         TPD_G => TPD_G)
      port map (
         clk      => refClk,
         asyncRst => reset,
         syncRst  => sysRst);

   MigCore : ddr4_0
      PORT MAP (
         c0_init_calib_complete => ddrCalDone,
         dbg_clk => open,
         c0_sys_clk_i => refClk,
         dbg_bus => open,
   
         c0_ddr4_adr => c0_ddr4_adr,
         c0_ddr4_ba => c0_ddr4_ba,
         c0_ddr4_cke => c0_ddr4_cke,
         c0_ddr4_cs_n => c0_ddr4_cs_n,
         c0_ddr4_dm_dbi_n => c0_ddr4_dm_dbi_n,
         c0_ddr4_dq => c0_ddr4_dq,
         c0_ddr4_dqs_c => c0_ddr4_dqs_c,
         c0_ddr4_dqs_t => c0_ddr4_dqs_t,
         c0_ddr4_odt => c0_ddr4_odt,
         c0_ddr4_bg => c0_ddr4_bg,
         c0_ddr4_reset_n => c0_ddr4_reset_n,
         c0_ddr4_act_n => c0_ddr4_act_n,
         c0_ddr4_ck_c => c0_ddr4_ck_c,
         c0_ddr4_ck_t => c0_ddr4_ck_t,
   
         c0_ddr4_ui_clk => ddrClk,
         c0_ddr4_ui_clk_sync_rst => coreRst(0),
         c0_ddr4_aresetn => axiRstL,
   
         c0_ddr4_s_axi_awid      => ddrWriteMaster.awid(3 downto 0),
         c0_ddr4_s_axi_awaddr    => ddrWriteMaster.awaddr(30 downto 0),
         c0_ddr4_s_axi_awlen     => ddrWriteMaster.awlen(7 downto 0),
         c0_ddr4_s_axi_awsize    => ddrWriteMaster.awsize(2 downto 0),
         c0_ddr4_s_axi_awburst   => ddrWriteMaster.awburst(1 downto 0),
         c0_ddr4_s_axi_awlock    => ddrWriteMaster.awlock(0 downto 0),
         c0_ddr4_s_axi_awcache   => ddrWriteMaster.awcache(3 downto 0),
         c0_ddr4_s_axi_awprot    => ddrWriteMaster.awprot(2 downto 0),
         c0_ddr4_s_axi_awqos     => ddrWriteMaster.awqos(3 downto 0),
         c0_ddr4_s_axi_awvalid   => ddrWriteMaster.awvalid,
         c0_ddr4_s_axi_awready   => ddrWriteSlave.awready,
   
         c0_ddr4_s_axi_wdata     => ddrWriteMaster.wdata(8*AXI_NBYTES_C-1 downto 0),
         c0_ddr4_s_axi_wstrb     => ddrWriteMaster.wstrb(AXI_NBYTES_C-1 downto 0),
         c0_ddr4_s_axi_wlast     => ddrWriteMaster.wlast,
         c0_ddr4_s_axi_wvalid    => ddrWriteMaster.wvalid,
         c0_ddr4_s_axi_wready    => ddrWriteSlave.wready,
         c0_ddr4_s_axi_bready    => ddrWriteMaster.bready,
         c0_ddr4_s_axi_bid       => ddrWriteSlave.bid(3 downto 0),
         c0_ddr4_s_axi_bresp     => ddrWriteSlave.bresp(1 downto 0),
         c0_ddr4_s_axi_bvalid    => ddrWriteSlave.bvalid,
         c0_ddr4_s_axi_arid      => ddrReadMaster.arid(3 downto 0),
         c0_ddr4_s_axi_araddr    => ddrReadMaster.araddr(30 downto 0),
         c0_ddr4_s_axi_arlen     => ddrReadMaster.arlen(7 downto 0),
         c0_ddr4_s_axi_arsize    => ddrReadMaster.arsize(2 downto 0),
         c0_ddr4_s_axi_arburst   => ddrReadMaster.arburst(1 downto 0),
         c0_ddr4_s_axi_arlock    => ddrReadMaster.arlock(0 downto 0),
         c0_ddr4_s_axi_arcache   => ddrReadMaster.arcache(3 downto 0),
         c0_ddr4_s_axi_arprot    => ddrReadMaster.arprot(2 downto 0),
         c0_ddr4_s_axi_arqos     => ddrReadMaster.arqos(3 downto 0),
         c0_ddr4_s_axi_arvalid   => ddrReadMaster.arvalid,
         c0_ddr4_s_axi_arready   => ddrReadSlave.arready,
         c0_ddr4_s_axi_rready    => ddrReadMaster.rready,
         c0_ddr4_s_axi_rlast     => ddrReadSlave.rlast,
         c0_ddr4_s_axi_rvalid    => ddrReadSlave.rvalid,
         c0_ddr4_s_axi_rresp     => ddrReadSlave.rresp(1 downto 0),
         c0_ddr4_s_axi_rid       => ddrReadSlave.rid(3 downto 0),
         c0_ddr4_s_axi_rdata     => ddrReadSlave.rdata(8*AXI_NBYTES_C-1 downto 0),
   
         sys_rst => sysRst
     );
   
   process(ddrClk)
   begin
      if rising_edge(ddrClk) then
         coreRst(1) <= coreRst(0) after TPD_G;  -- Register to help with timing
         ddrRst     <= coreRst(1) after TPD_G;  -- Register to help with timing
      end if;
   end process;

   -- Map the AXI4 buses
   ddrWriteMaster <= axiWriteMaster;
   axiWriteSlave  <= ddrWriteSlave;
   ddrReadMaster  <= axiReadMaster;
   axiReadSlave   <= ddrReadSlave;

   U_Sync : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => axilClk,
         dataIn  => ddrCalDone,
         dataOut => done);

   comb : process (alertL, axilReadMaster, axilRst, axilWriteMaster, done,
                   pg, r) is
      variable v      : RegType;
      variable regCon : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- Reset strobe signals
      v.ddrReset := '0';

      -- Determine the transaction type
      axiSlaveWaitTxn(regCon, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- Map the read registers
      axiSlaveRegisterR(regCon, x"100", 0, r.memReady);
      axiSlaveRegisterR(regCon, x"104", 0, r.memError);
      axiSlaveRegisterR(regCon, x"108", 0, x"00000000");  -- AxiMemTester's wTimer
      axiSlaveRegisterR(regCon, x"10C", 0, x"00000000");  -- AxiMemTester's rTimer
      axiSlaveRegisterR(regCon, x"110", 0, x"00000000");  -- AxiMemTester's START_C Lower word
      axiSlaveRegisterR(regCon, x"114", 0, x"00000000");  -- AxiMemTester's START_C Upper word
      axiSlaveRegisterR(regCon, x"118", 0, x"00000000");  -- AxiMemTester's STOP_C Lower word
      axiSlaveRegisterR(regCon, x"11C", 0, x"00000000");  -- AxiMemTester's STOP_C Upper word
      axiSlaveRegisterR(regCon, x"120", 0, toSlv(AXI_CONFIG_C.ADDR_WIDTH_C, 32));
      axiSlaveRegisterR(regCon, x"124", 0, toSlv(AXI_CONFIG_C.DATA_BYTES_C, 32));
      axiSlaveRegisterR(regCon, x"128", 0, toSlv(AXI_CONFIG_C.ID_BITS_C, 32));
      axiSlaveRegisterR(regCon, x"130", 0, alertL);
      axiSlaveRegisterR(regCon, x"134", 0, pg);

      -- Map the write registers
      axiSlaveRegister(regCon, x"3F8", 0, v.ddrPwrEn);
      axiSlaveRegister(regCon, x"3FC", 0, v.ddrReset);

      -- Closeout the transaction
      axiSlaveDefault(regCon, v.axilWriteSlave, v.axilReadSlave, AXI_ERROR_RESP_G);

      -- Latch the values from Synchronizers
      v.memReady := done;

      -- Synchronous Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      axilWriteSlave <= r.axilWriteSlave;
      axilReadSlave  <= r.axilReadSlave;
      memReady       <= r.memReady;
      memError       <= r.memError;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end mapping;
