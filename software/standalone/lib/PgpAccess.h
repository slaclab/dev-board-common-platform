#ifndef __PGP_ACCESS_H__
#define __PGP_ACCESS_H__

#include <string>
#include <stdint.h>
#include <PgpDriver.h>

using namespace std;

// Timeout in microseconds
#define REG_TIMEOUT 9000000

// Class to handle PGP access
class PgpAccess {

   private:  

      int      fd_;
      uint32_t lane_;
      uint32_t cmdVc_;
      uint32_t regVc_;

   public:

      // Constructor
      PgpAccess ( const char *path, uint32_t lane, uint32_t cmdVc, uint32_t regVc );

      // Deconstructor
      virtual ~PgpAccess ();

      // Write register
      int writeRegister ( uint32_t address, uint32_t count, uint32_t *data );

      // Read register
      int readRegister ( uint32_t address, uint32_t count, uint32_t *data );

      // Send command
      int sendCommand ( uint32_t opCode );

};

#endif
