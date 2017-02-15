#!/usr/bin/env python3
#-----------------------------------------------------------------------------
# Title      : PyRogue febBoard Module
#-----------------------------------------------------------------------------
# File       : febBoard.py
# Author     : Larry Ruckman <ruckman@slac.stanford.edu>
# Created    : 2016-11-09
# Last update: 2016-11-09
#-----------------------------------------------------------------------------
# Description:
# Rogue interface to FEB board
#-----------------------------------------------------------------------------
# This file is part of the ATLAS CHESS2 DEV. It is subject to 
# the license terms in the LICENSE.txt file found in the top-level directory 
# of this distribution and at: 
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
# No part of the ATLAS CHESS2 DEV, including this file, may be 
# copied, modified, propagated, or distributed except according to the terms 
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------
import rogue.hardware.pgp
import pyrogue.utilities.fileio
import pyrogue.gui
import pyrogue.protocols
import AtlasChess2Feb
import threading
import signal
import atexit
import yaml
import time
import sys
import PyQt4.QtGui

# Custom run control
class MyRunControl(pyrogue.RunControl):
   def __init__(self,name):
      pyrogue.RunControl.__init__(self,name,'Run Controller')
      self._thread = None

      self.runRate.enum = {1:'1 Hz', 10:'10 Hz', 100:'100 Hz'}

   def _setRunState(self,dev,var,value):
      if self._runState != value:
         self._runState = value

         if self._runState == 'Running':
            self._thread = threading.Thread(target=self._run)
            self._thread.start()
         else:
            self._thread.join()
            self._thread = None

   def _run(self):
      self._runCount = 0
      self._last = int(time.time())

      while (self._runState == 'Running'):
         delay = 1.0 / ({value: key for key,value in self.runRate.enum.items()}[self._runRate])
         time.sleep(delay)
         self._root.feb.sysReg.softTrig()

         self._runCount += 1
         if self._last != int(time.time()):
             self._last = int(time.time())
             self.runCount._updated()

def gui(arg):
    # Set base
    system = pyrogue.Root('System','Front End Board')

    # Run control
    system.add(MyRunControl('runControl'))

    # File writer
    dataWriter = pyrogue.utilities.fileio.StreamWriter('dataWriter')
    system.add(dataWriter)

    #################################################################
    # Check for PGP link
    if (arg == 'PGP'):
        # Create the PGP interfaces
        pgpVc0 = rogue.hardware.pgp.PgpCard('/dev/pgpcard_0',0,0) # Data
        pgpVc1 = rogue.hardware.pgp.PgpCard('/dev/pgpcard_0',0,1) # Registers

        # Display PGP card's firmware version
        print("")
        print("PGP Card Version: %x" % (pgpVc0.getInfo().version))
        print("")

        # Create and Connect SRPv0 to VC1
        srp = rogue.protocols.srp.SrpV0()
        pyrogue.streamConnectBiDir(pgpVc1,srp)
        
        # Add data stream to file as channel 1
        pyrogue.streamConnect(pgpVc0,dataWriter.getChannel(0x1))
    #################################################################
    # Else it's Ethernet based
    else:
        # Create the ETH interface @ IP Address = arg
        ethLink = pyrogue.protocols.UdpRssiPack(host=arg,port=8192,size=1400)    
    
        # Create and Connect SRPv0 to AxiStream.tDest = 0x0
        srp = rogue.protocols.srp.SrpV0()  
        pyrogue.streamConnectBiDir(srp,ethLink.application(0))

        # Add data stream to file as channel 1 to tDest = 0x1
        pyrogue.streamConnect(ethLink.application(1),dataWriter.getChannel(0x1))
    #################################################################
             
    # Add registers
    system.add(AtlasChess2Feb.feb(memBase=srp))
    
    # Get the updated variables
    system.readAll()
    
    # print ('Load the matrix')
    # system.feb.Chess2Ctrl0.loadMatrix()
    # system.feb.Chess2Ctrl1.loadMatrix()
    # system.feb.Chess2Ctrl2.loadMatrix()
    
    #####################################################
    # Example: Enable only one pixel for charge injection
    #####################################################
    # print ('Disable all pixels')
    # system.feb.Chess2Ctrl0.writeAllPixels(enable=0,chargeInj=0)
    # # Enable only one pixel for charge injection
    # print ('Enable only one pixels')
    # system.feb.Chess2Ctrl0.writePixel(enable=1, chargeInj=1, col=0, row=0)
    
    # Create GUI
    appTop = PyQt4.QtGui.QApplication(sys.argv)
    guiTop = pyrogue.gui.GuiTop('PyRogueGui')
    guiTop.resize(800, 1000)
    guiTop.addTree(system)
    
    # Run gui
    appTop.exec_()

    # Stop mesh after gui exits
    system.stop()

if __name__ == '__main__':
    gui(sys.argv[1])
