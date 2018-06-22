-------------------------------------------------------------------------------
-- File       : SimTimingClkGen.vhd
-- Company    : SLAC National Accelerator Laboratory
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

entity SimTimingClkGen is
   port (
      clk156p25      : in  sl;
      rst156p25      : in  sl;

      timingClkLcls1 : out sl;
      timingRstLcls1 : out sl;
      timingClkLcls2 : out sl;
      timingRstLcls2 : out sl
   );
end entity SimTimingClkGen;

architecture mapping of SimTimingClkGen is
begin
   U_ClockGen : entity work.ClockManagerUltraScale
      generic map (
         NUM_CLOCKS_G       => 2,
         CLKIN_PERIOD_G     => 6.4, -- 156.25MHz
         DIVCLK_DIVIDE_G    => 4,
         CLKFBOUT_MULT_F_G  => 24.375, -- VCO: 952.148

         CLKOUT0_DIVIDE_F_G => 5.125, -- 185.785MHz (~1300/7MHz)
         CLKOUT1_DIVIDE_G   => 8      -- 119.019MHz (~ 119  MHz)
      )
      port map (
         clkIn              => clk156p25,
         rstIn              => rst156p25,

         clkOut(0)          => timingClkLcls2,
         clkOut(1)          => timingClkLcls1,

         rstOut(0)          => timingRstLcls2,
         rstOut(1)          => timingRstLcls1
      );
end architecture mapping;
