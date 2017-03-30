#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue feb Module
#-----------------------------------------------------------------------------
# File       : _feb.py
# Created    : 2017-02-15
# Last update: 2017-02-15
#-----------------------------------------------------------------------------
# Description:
# PyRogue Feb Module
#-----------------------------------------------------------------------------
# This file is part of the 'Development Board Examples'. It is subject to 
# the license terms in the LICENSE.txt file found in the top-level directory 
# of this distribution and at: 
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
# No part of the 'Development Board Examples', including this file, may be 
# copied, modified, propagated, or distributed except according to the terms 
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import pyrogue as pr

import surf
import surf.AxiVersion

class feb(pr.Device):
    def __init__(self, name="feb", memBase=None, offset=0, hidden=False):
        super(self.__class__, self).__init__(name, "feb Module",
                                             memBase=memBase, offset=offset, hidden=hidden)        
        #############
        # Add devices
        #############
        self.add(surf.AxiVersion.create(   offset=0x00000000,expand=False))
     