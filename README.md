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
   can be connected to the second SFP port (The one closer to the edge
   of the board, farther from the RJ45 connector). The on-board Si5328 oscillator
   generates suitable reference clocks and is automatically switched/programmed
   when the user switches the TimingRx between the lcls-1 and lcls-2 modes
   (`TimingFrameRx/ClkSel:`).

   Note that the KCU105 'System Controller' also manipulates the i2c bus.
   Make sure you don't use the system controller concurrently with switching
   the clock mode.

   If no timing fiber is available then the GTH transceiver can be set into
   loopback mode (`TPGMiniCore/TxLoopback: 2`).

   By default the trigger channels 8 and 9 are routed to the board's GPIO
   SMA connectors (P and N, respectively).

 - **BSA**: Lcls-2 style BSA is available.
 - **DaqMuxV2**: Shares the DDR memory with the BSA core.
 - **XVC Support**: Remote connection to ILAs over XVC.
 - **DAC Signal Generator**
 - **Backplane Messaging**
 - **Fan Control**: When the board sits on your desk the fan can be quite
   annoying. The fan-controller implements a simple P-controller to keep
   noise and temperature in check. It is disabled/bypassed by default, however
   (`FanController/Bypass: 1`). The controller is also overridden if the
   SysMon detects a temperature alarm condition (85degC).

### Networking
The firmware provides 10/100/1000 ethernet at the RJ45 jack as well as
10G ethernet at the SFP0 bay (the one closer to the RJ-45).

The link speed of the 10/100/1000 port is auto-negotiated (auto-negotiation
can *not* be disabled).

During reset the state of the DIP switch (4-position switch, SW12) in
position 0 (leftmost bit) is sampled to drive a multiplexer which selects
RJ45 vs. SFP0/10G ethernet. 10G is selected if the switch is in the 'on'
position. Note that the setting is only sampled during reset and ignored
otherwise.

Support for 10G ethernet may be disabled at compile-time (e.g., if the
application needs to use the SFP) by setting the `DISABLE_10G_ETH` variable
in the Makefile. Note that it is the user's responsibility to drive the
respective top-level ports if 10G ethernet support is disabled.

#### MAC/IP Addresses
The addresses are configurable (via `AppCoreConfigPkg`, see below) but
hard-coded in the image. This can be problematic if multiple boards
are connected to the same subnet. Different IP addresses may be assigned
by using BOOTP/DHCP (enabled by default) - however, the hard-coded MAC
address still may lead to conflicts. In order to mitigate this, the
three rightmost bits (pos 1..4) of DIP switch SW12 are sampled during
reset of the board and XORed with the three least-significant bits
of the hardcoded MAC as well as the IP address.

The default addresses are (with the 3 DIP switches in OFF position):

- IP:  `192.168.2.10`
- MAC: `00:44:56:00:03:01`

Thus, if the switch in pos.-4 is ON the IP address becomes `192.168.2.11`
and the MAC address `00:44:56:00:03:00`.

### LEDs
Unless the ("user-") LEDs are re-purposed by the Application Core they provide the following information:

- **LED-7** (leftmost): 10/100/1000 Ethernet link status.
- **LED-6**: 10/100/1000 Ethernet: speed auto-negotiated to 1G
- **LED-5**: 10/100/1000 Ethernet: speed auto-negotiated to 100 or 1000
  (=> 10Mb when off).
- **LED-4**: DRAM ready.

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
The user also must provide a package `AppCoreConfigPkg.vhd` where
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

## Release Notes
Note: odd 3rd number is used for added image files
v1.0.0: Initial Release
v1.0.1: Image files added
v1.1  : Use Si5328 to generate ethernet clocks
        Run-time switching between 10G(SRP)/1G(RJ45) ethernet
        Added PMOD (and some other) connectors
        Renamed target subdirectory to Kcu105Eth
v1.1.1: Image files added
v1.2.0: Added 'backdoor' controller (SRPV2 over UDP @8192)
        Added MAC registers
        Added ethernet transceiver registers
        Jumbo frame support (use surf with ESLCOMMON-229 patch)

## Acknowledgement

This project has been derived from <git@github.com/slaclab/dev-board-examples>
and is released under the same [license](LICENSE.txt). It has been made a separate project
because it is currently not possible to create a fork within a single organization
on github.com.
