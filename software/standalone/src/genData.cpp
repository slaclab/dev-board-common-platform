#include <string>
#include <stdio.h>
#include <stdint.h>
#include "../lib/EvalBoard.h"

int main ( int argc, char **argv ) {
   EvalBoard * eval;

   eval = new EvalBoard ("/dev/pgpcard_0");

   eval->setPrbsLength(256);

   while (1) {
      eval->genPrbsFrame();
      usleep(100000);
   }

   delete eval;
}

