-- ==============================================================
-- File generated by Vivado(TM) HLS - High-Level Synthesis from C, C++ and SystemC
-- Version: 2016.4
-- Copyright (C) 1986-2017 Xilinx, Inc. All Rights Reserved.
-- 
-- ==============================================================


------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
COMPONENT AxiStreamExampleCore
  PORT (
    axisSlave_TDATA : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    axisSlave_TKEEP : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    axisSlave_TSTRB : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    axisSlave_TUSER : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    axisSlave_TLAST : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    axisSlave_TID : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    axisSlave_TDEST : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    axisMaster_TDATA : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    axisMaster_TKEEP : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axisMaster_TSTRB : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axisMaster_TUSER : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    axisMaster_TLAST : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    axisMaster_TID : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    axisMaster_TDEST : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    ap_clk : IN STD_LOGIC;
    ap_rst_n : IN STD_LOGIC;
    axisSlave_TVALID : IN STD_LOGIC;
    axisSlave_TREADY : OUT STD_LOGIC;
    axisMaster_TVALID : OUT STD_LOGIC;
    axisMaster_TREADY : IN STD_LOGIC
  );
END COMPONENT;
-- COMP_TAG_END ------ End COMPONENT Declaration ------------

-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.

------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
your_instance_name : AxiStreamExampleCore
  PORT MAP (
    axisSlave_TDATA => axisSlave_TDATA,
    axisSlave_TKEEP => axisSlave_TKEEP,
    axisSlave_TSTRB => axisSlave_TSTRB,
    axisSlave_TUSER => axisSlave_TUSER,
    axisSlave_TLAST => axisSlave_TLAST,
    axisSlave_TID => axisSlave_TID,
    axisSlave_TDEST => axisSlave_TDEST,
    axisMaster_TDATA => axisMaster_TDATA,
    axisMaster_TKEEP => axisMaster_TKEEP,
    axisMaster_TSTRB => axisMaster_TSTRB,
    axisMaster_TUSER => axisMaster_TUSER,
    axisMaster_TLAST => axisMaster_TLAST,
    axisMaster_TID => axisMaster_TID,
    axisMaster_TDEST => axisMaster_TDEST,
    ap_clk => ap_clk,
    ap_rst_n => ap_rst_n,
    axisSlave_TVALID => axisSlave_TVALID,
    axisSlave_TREADY => axisSlave_TREADY,
    axisMaster_TVALID => axisMaster_TVALID,
    axisMaster_TREADY => axisMaster_TREADY
  );
-- INST_TAG_END ------ End INSTANTIATION Template ------------
