-------------------------------------------------------------------------------
-- File       : AppCore.vhd
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
use ieee.numeric_std.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.TimingPkg.all;
use work.AmcCarrierPkg.all;
use work.Jesd204bPkg.all;
use work.AppTopPkg.all;
use work.AppCorePkg.all;

-- Note: use single definition of entity in AppTop/rtl/AppCoreEntity.vhd

architecture Stub of AppCore is
begin

   -- loop back the application streams
   obAxisMasters  <= ibAxisMasters;
   ibAxisSlaves   <= obAxisSlaves;

end architecture Stub;
