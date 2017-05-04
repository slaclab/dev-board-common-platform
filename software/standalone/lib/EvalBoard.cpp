#include <string>
#include <stdint.h>
#include "EvalBoard.h"

// Constructor
EvalBoard::EvalBoard ( const char *path ) : PgpAccess (path, 0, 1, 0) { }

// Set PRBS packet length
int EvalBoard::setPrbsLength ( uint32_t length ) {
   uint32_t data;

    // Set axi enable
   data = 1;
   if ( this->writeRegister(0x00040000,1,&data) < 0 ) return(-1);

   // Set length
   data = length;
   return(this->writeRegister(0x00040004,1,&data));
}

// Get PRBS packet length
int EvalBoard::getPrbsLength ( uint32_t *length ) {
   return(this->readRegister(0x00040004,1,length));
}

// Generate a single PRBS frame
int EvalBoard::genPrbsFrame ( ) {
   uint32_t data = 0x10;
   return(this->writeRegister(0x00040000,1,&data));
}

// Write scratchpad
int EvalBoard::setScratchpad ( uint32_t value ) {
   uint32_t data = value;
   return(this->writeRegister(0x00000004,1,&data));
}

// Read scratchpad
int EvalBoard::getScratchpad ( uint32_t *value ) {
   return(this->readRegister(0x00000004,1,value));
}

// Get buildstamp, (256 charactors max)
int EvalBoard::getBuildStamp ( char *stamp ) {
   uint32_t * data = (uint32_t *)stamp;
   return(this->readRegister(0x00000800,64,data));
}

// Get heartbeat counter
int EvalBoard::getHeartBeat ( uint32_t *value ) {
   return(this->readRegister(0x00000024,1,value));
}

// Get deviceDNA 
int EvalBoard::getDeviceDna ( uint64_t *value ) {
   return(this->readRegister(0x00000008,2,(uint32_t *)value));
}

// Get firmware version
int EvalBoard::getFwVersion ( uint32_t *value ) {
   return(this->readRegister(0x00000000,1,value));
}

