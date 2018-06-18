-------------------------------------------------------------------------------
-- File       : AppCore.vhd
-- Company    : SLAC National Accelerator Laboratory
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

entity AppCore is
   generic (
      TPD_G               : time                  := 1 ns;
      XIL_DEVICE_G        : string                := "7SERIES";
      AXIL_CLK_FRQ_G      : real                  := 156.25E6;
      AXIL_BASE_ADDR_G    : slv(31 downto 0);
      APP_CORE_CONFIG_G   : AppCoreConfigType
   );
   port (
      -- Clock and Reset
      axilClk         : in  sl;
      axilRst         : in  sl;
      -- AXI-Lite interface
      sAxilWriteMaster: in  AxiLiteWriteMasterType;
      sAxilWriteSlave : out AxiLiteWriteSlaveType  := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;
      sAxilReadMaster : in  AxiLiteReadMasterType;
      sAxilReadSlave  : out AxiLiteReadSlaveType   := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;

      mAxilWriteMaster: out AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
      mAxilWriteSlave : in  AxiLiteWriteSlaveType;
      mAxilReadMaster : out AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
      mAxilReadSlave  : in  AxiLiteReadSlaveType;

      -- Streams
      obAxisMasters   : out AxiStreamMasterArray   := (others => AXI_STREAM_MASTER_INIT_C);
      obAxisSlaves    : in  AxiStreamSlaveArray;
      ibAxisMasters   : in  AxiStreamMasterArray;
      ibAxisSlaves    : out AxiStreamSlaveArray    := (others => AXI_STREAM_SLAVE_FORCE_C);

      -- Timing Interface
      timingClk       : in  sl;
      timingRst       : in  sl;
      timingBus       : in  TimingBusType;
      timingTrig      : in  TimingTrigType;

      -- Diagnostic Interface
      diagnosticClk   : out sl := '0';
      diagnosticRst   : out sl := '0';
      diagnosticBus   : out diagnosticBusType := DIAGNOSTIC_BUS_INIT_C;

      -- JESD
      jesdClk         : in  slv(1 downto 0);
      jesdRst         : in  slv(1 downto 0);
      jesdClk2x       : in  slv(1 downto 0);
      jesdRst2x       : in  slv(1 downto 0);
      jesdUsrClk      : in  slv(1 downto 0);
      jesdUsrRst      : in  slv(1 downto 0);

      freezeHw        : out slv(1 downto 0) := "00";
      trigHw          : out slv(1 downto 0) := "00";
      trigCascBay     : in  slv(1 downto 0);

      adcValids       : in  Slv7Array(1 downto 0);
      adcValues       : in  sampleDataVectorArray(1 downto 0, 6 downto 0);
      dacValids       : out Slv7Array(1 downto 0) := (others => "0000000");
      dacValues       : out sampleDataVectorArray(1 downto 0, 6 downto 0) := (others => (others => (others => '0')));
      debugValids     : out Slv4Array(1 downto 0) := (others => "0000");
      debugValues     : out sampleDataVectorArray(1 downto 0, 3 downto 0) := (others => (others => (others => '0')));

      -- DAC Signal Generator (jesd 1x if SIG_GEN_LANE_MODE == '0', jesd 2x otherwise)
      dacSigCtrl      : out DacSigCtrlArray(1 downto 0) := (others => DAC_SIG_CTRL_INIT_C);
      dacSigStatus    : in  DacSigStatusArray(1 downto 0);
      dacSigValids    : in  Slv7Array(1 downto 0);
      dacSigValues    : in  sampleDataVectorArray(1 downto 0, 6 downto 0);
      gpioDip         : in  slv(                               3 downto 0);
      appLeds         : out slv(APP_CORE_CONFIG_G.numAppLEDs - 1 downto 0) := (others => '0')
   );
end entity AppCore;

architecture Stub of AppCore is
begin
end architecture Stub;
