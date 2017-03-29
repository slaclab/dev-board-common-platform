-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : StaticDesign.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2014-01-13
-- Last update: 2014-01-14
-- Platform   : Vivado2013.3
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Simple Partial Reconfiguration Example
-------------------------------------------------------------------------------
-- Copyright (c) 2014 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;

library unisim;
use unisim.vcomponents.all;

entity StaticDesign is
   port (
      clkP : in  sl;
      clkN : in  sl;
      led  : out slv(7 downto 0));
end StaticDesign;

architecture top_level of StaticDesign is

   -- Signals
   signal clk,
      testPointA,
      testPOintB : sl;
   signal cnt : slv(31 downto 0) := (others => '0');

   -- Declare the Reconfigurable RTL as a black box
   -- and don't include its RTL file (.vhd or .v) 
   -- during the initial synthesis process 
   component LedRtlA
      port (
         clk : in  sl;
         cnt : in  slv(31 downto 0);
         led : out sl);
   end component;
   attribute BOX_TYPE of LedRtlA : component is "BLACK_BOX";
   
   component LedRtlB
      port (
         clk : in  sl;
         cnt : in  slv(31 downto 0);
         led : out sl);
   end component;
   attribute BOX_TYPE of LedRtlB : component is "BLACK_BOX";   
   
begin

   -- Reference Clock
   IBUFGDS_Inst : IBUFGDS
      port map (
         I  => clkP,
         IB => clkN,
         O  => clk);  

   -- Static RTL Core
   CntRtl_Inst : entity work.CntRtl
      port map (
         clk => clk,
         cnt => cnt);

   -- Reconfigurable RTL Core
   LedRtlA_Inst : LedRtlA
      port map (
         clk => clk,
         cnt => cnt,
         led => testPointA);
         
   -- Reconfigurable RTL Core
   LedRtlB_Inst : LedRtlB
      port map (
         clk => clk,
         cnt => cnt,
         led => testPointB);         

   -- Misc.
   led <= x"8" & "00" & testPointB & testPointA;
   
end top_level;
----------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.StdRtlPkg.all;

entity LedRtlA is
   port (
      clk : in  sl;
      cnt : in  slv(31 downto 0);
      led : out sl);
end LedRtlA;
----------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.StdRtlPkg.all;

entity LedRtlB is
   port (
      clk : in  sl;
      cnt : in  slv(31 downto 0);
      led : out sl);
end LedRtlB;
----------------------------------
