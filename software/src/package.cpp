/**
 *-----------------------------------------------------------------------------
 * Title      : Python Package
 * ----------------------------------------------------------------------------
 * File       : package.cpp
 * Author     : Ryan Herbst, rherbst@slac.stanford.edu
 * Created    : 2016-10-23
 * Last update: 2016-10-23
 * ----------------------------------------------------------------------------
 * Description:
 * Python package setup
 * ----------------------------------------------------------------------------
 * This file is part of the rogue_example software. It is subject to 
 * the license terms in the LICENSE.txt file found in the top-level directory 
 * of this distribution and at: 
 *    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
 * No part of the rogue_example software, including this file, may be 
 * copied, modified, propagated, or distributed except according to the terms 
 * contained in the LICENSE.txt file.
 * ----------------------------------------------------------------------------
**/

#include <boost/python.hpp>
// #include "StreamSink.h"

BOOST_PYTHON_MODULE(rogue_example) {

   PyEval_InitThreads();

   // StreamSink::setup_python();

};

