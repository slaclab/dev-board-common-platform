#include <string>
#include <stdio.h>
#include <stdint.h>
#include "../lib/EvalBoard.h"

int main ( int argc, char **argv ) {
   EvalBoard * eval;
   uint32_t    tmpInt;
   char        tmpChar[257];

   eval = new EvalBoard ("/dev/pgpcard_0");

   eval->getFwVersion(&tmpInt);
   printf("FwVersion   = 0x%.8X\n",tmpInt);

   eval->getBuildStamp(tmpChar);
   printf("BuildStamp  = %s\n",tmpChar);

   eval->getHeartBeat(&tmpInt);
   printf("HeartBeat   = 0x%.8X\n",tmpInt);

   eval->getScratchpad(&tmpInt);
   printf("Scratchpad  = 0x%.8X\n",tmpInt);

   eval->getPrbsLength(&tmpInt);
   printf("PRBS Length = %i\n",tmpInt);

   delete eval;
}

