#include <string>
#include <stdint.h>
#include <stdio.h>
#include <fcntl.h>
#include "PgpAccess.h"

// Constructor
PgpAccess::PgpAccess ( const char *path, uint32_t lane, uint32_t cmdVc, uint32_t regVc ) {
   uint8_t mask[DMA_MASK_SIZE];

   fd_    = open(path,O_RDWR);
   lane_  = lane;
   cmdVc_ = cmdVc;
   regVc_ = regVc;

   if ( fd_ < 0 ) {
      fprintf(stderr,"PgpAccess::PgpAccess -> Could not open PGP path %s\n",path);
      throw((int32_t)-1);
   }

   // Set rx mask bits for register channel
   // Don't set mask for command channel since we will only send on that
   // channel. Data receive will be done elsewhere.
   dmaInitMaskBytes(mask);
   dmaAddMaskBytes(mask,(lane_*4)+regVc_);

   if ( dmaSetMaskBytes(fd_,mask) < 0 ) {
      fprintf(stderr,"PgpAccess::PgpAccess -> Failed to reserve VC\n");
      ::close(fd_);
      throw((int32_t)-1);
   }   
}

// Deconstructor
PgpAccess::~PgpAccess () {
   ::close(fd_);
}

// Write register
int PgpAccess::writeRegister ( uint32_t address, uint32_t count, uint32_t *data ) {
   uint32_t txBuffer[count + 3];
   uint32_t rxBuffer[count + 3];
   uint32_t error;
   int32_t  res;
   struct   timeval tout;
   fd_set   fds;

   // Format the request
   txBuffer[0]  = 0x5a5a5a5a; // Context echo unused
   txBuffer[1]  = 0x40000000; // Bits 31:30 = opcode = 1 for write
   txBuffer[1] += (address >> 2) & 0x3FFFFFFF; // Addresses are 32-bits aligned
   txBuffer[2+count] = 0;

   // Copy data
   memcpy(txBuffer+2,data,count*4);

   // Send the request
   dmaWrite(fd_, txBuffer, (count+3)*4, 0,pgpSetDest(lane_, regVc_));

   // Wait on response
   FD_ZERO(&fds);
   FD_SET(fd_,&fds);

   // Setup select timeout
   tout.tv_sec=(REG_TIMEOUT / 1000000);
   tout.tv_usec=(REG_TIMEOUT % 1000000);

   if ( select(fd_+1,&fds,NULL,NULL,&tout) <= 0 ) {
      fprintf(stderr,"PgpAccess::writeRegister -> Timeout accessing register %x\n",address);
      return(-1); // timeout
   }

   // Attempt read, dest not needed since only one lane/vc is open
   res = dmaRead(fd_, rxBuffer, (count+3)*4, NULL, &error, NULL);

   // Error or no data
   if ( res <= 0 || error != 0 ) {
      fprintf(stderr,"PgpAccess::writeRegister -> Frame read error accessing register %x\n",address);
      return(-1);
   }

   return(count);
}

// Read register
int PgpAccess::readRegister ( uint32_t address, uint32_t count, uint32_t *data ) {
   uint32_t txBuffer[4];
   uint32_t rxBuffer[count + 3];
   uint32_t error;
   int32_t  res;
   struct   timeval tout;
   fd_set   fds;

   // Format the request
   txBuffer[0]  = 0x5a5a5a5a; // Context echo unused
   txBuffer[1]  = 0x00000000; // Bits 31:30 = opcode = 0 for read
   txBuffer[1] += (address >> 2) & 0x3FFFFFFF; // Addresses are 32-bits aligned
   txBuffer[2]  = count-1;
   txBuffer[3]  = 0;

   // Send the request
   dmaWrite(fd_, txBuffer, 16, 0, pgpSetDest(lane_, regVc_));

   // Wait on response
   FD_ZERO(&fds);
   FD_SET(fd_,&fds);

   // Setup select timeout
   tout.tv_sec=(REG_TIMEOUT / 1000000);
   tout.tv_usec=(REG_TIMEOUT % 1000000);

   if ( select(fd_+1,&fds,NULL,NULL,&tout) <= 0 ) {
      fprintf(stderr,"PgpAccess::readRegister -> Timeout accessing register %x\n",address);
      return(-1); // timeout
   }

   // Attempt read, dest not needed since only one lane/vc is open
   res = dmaRead(fd_, rxBuffer, (count+3)*4, NULL, &error, NULL);

   // Error or no data
   if ( res <= 0 || error != 0 ) {
      fprintf(stderr,"PgpAccess::readRegister -> Frame read error accessing register %x\n",address);
      return(-1);
   }

   // Copy data
   memcpy(data,rxBuffer+2,count*4);

   return(count);
}

// Send command
int PgpAccess::sendCommand ( uint32_t opCode ) {
   uint32_t txBuffer[4];

   // Format the request
   txBuffer[0]  = 0;
   txBuffer[1]  = opCode & 0xFF;
   txBuffer[2]  = 0;
   txBuffer[3]  = 0;

   // Send the request
   return(dmaWrite(fd_, txBuffer, 16, 0, pgpSetDest(lane_, cmdVc_)));
}

