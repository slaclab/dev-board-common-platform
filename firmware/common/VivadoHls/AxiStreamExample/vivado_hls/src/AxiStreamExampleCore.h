//////////////////////////////////////////////////////////////////////////////
// This file is part of 'Vivado HLS Example'.
// It is subject to the license terms in the LICENSE.txt file found in the 
// top-level directory of this distribution and at: 
//    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
// No part of 'Vivado HLS Example', including this file, 
// may be copied, modified, propagated, or distributed except according to 
// the terms contained in the LICENSE.txt file.
//////////////////////////////////////////////////////////////////////////////

#ifndef _AXI_STREAM_EXAMPLE_CORE_H_
#define _AXI_STREAM_EXAMPLE_CORE_H_

#include <stdio.h>

#include "ap_axi_sdata.h"
#include "hls_stream.h"


typedef ap_axis<32,2,1,1> AXIS_STREAM;

#endif
