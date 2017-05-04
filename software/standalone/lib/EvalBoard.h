#ifndef __EVAL_BOARD_H__
#define __EVAL_BOARD_H__

#include <string>
#include <stdint.h>
#include "PgpAccess.h"

using namespace std;

// Class to handle PGP access
class EvalBoard : public PgpAccess {

   public:

      // Constructor
      EvalBoard ( const char *path );

      // Set PRBS packet length
      int setPrbsLength ( uint32_t length );

      // Get PRBS packet length
      int getPrbsLength ( uint32_t *length );

      // Generate a single PRBS frame
      int genPrbsFrame ( );

      // Write scratchpad
      int setScratchpad ( uint32_t value );

      // Read scratchpad
      int getScratchpad ( uint32_t *value );

      // Get buildstamp, (256 charactors max)
      int getBuildStamp ( char *stamp );

      // Get heartbeat counter
      int getHeartBeat ( uint32_t *value );

      // Get deviceDNA 
      int getDeviceDna ( uint64_t *value );

      // Get firmware version
      int getFwVersion ( uint32_t *value );

};

#endif
