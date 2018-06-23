# SLAC Common Platform Environment on a Development Board

## Introduction
This project aims at porting most of the features of the *Common Platform*
to the (KCU105) development board which is convenient for development and
testing since the user does not need a full-blown ATCA system. A development
board is quick to set up, portable and can be operated without the need to
coordinate with other users.

## Features
Most of the important features of the *Common Platform* are available:
 - **Timing**: If available an external timing fiber (lcls-1 or lcls-2) 
   can be connected to the first SFP port. The on-board Si570 oscillator
   generates suitable reference clocks and is automatically switched/programmed
   when the user switches the TimingRx between the lcls-1 and lcls-2 modes
   (`TimingFrameRx/ClkSel:`).
   If no timing fiber is available then the GTH transceiver can be set into
   loopback mode (`TPGMiniCore/TxLoopback: 2`).

   By default the trigger channels 8 and 9 are routed to the board's GPIO
   SMA connectors (P and N, respectively).

 - **BSA**: Lcls-2 style BSA is available.
 - **DaqMuxV2**: Shares the DDR memory with the BSA core.
 - **XVC Support**: Remote connection to ILAs with over XVC.
 - **DAC Signal Generator**
 - **Backplane Messaging**
 - **Fan Control**: When the board sits on your desk the fan can be quite
   annoying. The fan-controller implements a simple P-controller to keep
   noise and temperature in check. It is disabled/bypassed by default, however
   (`FanController/Bypass: 1`). The controller is also overridden if the
   SysMon detects a temperature alarm condition (85degC).

## User-Application Integration
The interface to the application core is declared by the 'AppCore' entity.
The user is supposed to provide his/her implementation under 
`firmware/common/core/`. If no such directory is present then the build-scripts
use the stub `firmware/common/coreStub` which also serves as a template.

Currently, no external connections of ADCs or DACs are available (DACs are
simply looped-back to ADCs) but real devices on FMCs could be supported in
the future.

The assumption is that the user's application code contains some kind of
simulator which can produce simulated signals.

### Configurable Features
The user also must provide a package '`AppCoreConfigPkg.vhd`' where
the constant `APP_CORE_CONFIG_C` is defined. This constant is a record
with several fields that define configurable parameters of the platform.
Consult `AppTop/rtl/AppCorePkg.vhd` for more information.

## Other Use Cases
The bare platform (without any application firmware) can easily be
configured (at run-time) to produce LCLS-1 style timing signals (and
data streams) and can thus be used as a stand-alone timing and LCLS-1
BSA source for development and testing of LCLS-1 software applications.

Note that a proper level-shifter is likely to be required on the SMA triggers
since their voltage level is 1.8V only.

## Clone the GIT repository
```
$ git clone --recursive git@github.com:/slaclab/dev-board-common-platform
```

Note that you need git LFS. If you are unfamiliar with the basic steps
for cloning and building SLAC firmware please consult
<https://github.com/slaclab/dev-board-examples>

## Acknowledgement

This project has been derived from <git@github.com/slaclab/dev-board-examples>
and is released under the same [license](LICENSE.txt). It has been made a separate project
because it is currently not possible to create a fork within a single organization
on github.com.
