-------------------------------------------------------------------------------
-- File       : SimJesdClkGen.vhd
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

entity SimJesdClkGen is
   generic (
      INPT_CLK_FREQ_G  : real;
      JESD_CLK_IDIV_G  : positive;
      JESD_CLK_MULT_G  : real;
      JESD_CLK_ODIV_G  : positive;
      USER_CLK_ODIV_G  : positive
   );
   port (
      clkIn          : in  sl;
      rstIn          : in  sl;

      userClk        : out sl;
      jesdClk        : out sl;
      jesdClk2x      : out sl;
      userRst        : out sl;
      jesdRst        : out sl;
      jesdRst2x      : out sl
   );
end entity SimJesdClkGen;

architecture mapping of SimJesdClkGen is
begin
   U_ClockGen : entity work.ClockManagerUltraScale
      generic map (
         NUM_CLOCKS_G       => 3,
         CLKIN_PERIOD_G     => (1.0E9/INPT_CLK_FREQ_G),
         DIVCLK_DIVIDE_G    => JESD_CLK_IDIV_G,
         CLKFBOUT_MULT_F_G  => JESD_CLK_MULT_G,

         CLKOUT0_DIVIDE_G   => JESD_CLK_ODIV_G,
         CLKOUT1_DIVIDE_G   => (2*JESD_CLK_ODIV_G),
         CLKOUT2_DIVIDE_G   => USER_CLK_ODIV_G
      )
      port map (
         clkIn              => clkIn,
         rstIn              => rstIn,

         clkOut(2)          => userClk,
         clkOut(1)          => jesdClk,
         clkOut(0)          => jesdClk2x,

         rstOut(2)          => userRst,
         rstOut(1)          => jesdRst,
         rstOut(0)          => jesdRst2x
      );

end architecture mapping;
