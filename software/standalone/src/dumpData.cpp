#include <string>
#include <stdio.h>
#include <fcntl.h>
#include <stdint.h>
#include <PgpDriver.h>

#define MAX_DATA 1000000

int main ( int argc, char **argv ) {
   uint32_t data[MAX_DATA];
   uint32_t error;
   int32_t  fd;
   struct   timeval tout;
   fd_set   fds;
   int32_t  res;

   uint8_t mask[DMA_MASK_SIZE];

   fd = open("/dev/pgpcard_0",O_RDWR);

   if ( fd < 0 ) {
      fprintf(stderr,"Could not open PGP card\n");
      return(-1);
   }

   // Set rx mask bits for data channel
   dmaInitMaskBytes(mask);
   dmaAddMaskBytes(mask,0x1);

   if ( dmaSetMaskBytes(fd,mask) < 0 ) {
      fprintf(stderr,"Failed to reserve VC\n");
      ::close(fd);
      return(-1);
   }   

   while (1) {

      // Wait on response
      FD_ZERO(&fds);
      FD_SET(fd,&fds);

      // Setup select timeout
      tout.tv_sec=0;
      tout.tv_usec=10000;

      if ( select(fd+1,&fds,NULL,NULL,&tout) > 0 ) {

         // Attempt read, dest not needed since only one lane/vc is open
         res = dmaRead(fd, data, MAX_DATA*4, NULL, &error, NULL);
         printf("Got Data. Size=%i, error=%i\n",res,error);
      }
   }
}

