//////////////////////////////////////////////////////////////////////////////
// This file is part of 'Example Project Firmware'.
// It is subject to the license terms in the LICENSE.txt file found in the 
// top-level directory of this distribution and at: 
//    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
// No part of 'Example Project Firmware', including this file, 
// may be copied, modified, propagated, or distributed except according to 
// the terms contained in the LICENSE.txt file.
//////////////////////////////////////////////////////////////////////////////
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stdint.h>

#include "xil_types.h"
#include "xil_io.h"
#include "ssi_printf.h"
#include "xintc.h"
#include "xparameters.h"
#include "xtmrctr.h"

#define BUS_OFFSET  0x80000000
#define AXI_VERSION (BUS_OFFSET+0x00000000)
#define AXI_MEMORY  (BUS_OFFSET+0x00020000)

void My_Mem_Handler(void * data) {
   uint32_t val = Xil_In32(AXI_MEMORY + 4092);
   ssi_printf("Got mem write: %u\n",val);
}

void My_Handler(void * data) {
   uint32_t * cnt = (uint32_t *)data;
 
   (*cnt) ++; 
   ssi_printf("Irq: %u\n",*cnt);
}

void My_Timer(void * data, unsigned char num ) {
   uint32_t * cnt = (uint32_t *)data;
 
   (*cnt) ++; 
   ssi_printf("Timer %u, count %u\n",num,*cnt);
}

int main() {
   char *       bldString;
   uint32_t     icount;
   uint32_t     tcount;
   XIntc        intc;
   XTmrCtr      tmrctr;

   bldString = (char *)(AXI_VERSION + 0x800);

   ssi_printf_init(AXI_MEMORY,2048);

   ssi_printf("Hello world!\n");
   ssi_printf("Build: %s\n",bldString);

   ssi_printf("Setting up interrupt & timer\n");
   icount = 0;
   tcount = 0;

   XTmrCtr_Initialize(&tmrctr,0);
   XIntc_Initialize(&intc,0);
   microblaze_enable_interrupts();

   XIntc_Connect(&intc,8,XTmrCtr_InterruptHandler,&tmrctr);
   XIntc_Connect(&intc,0,(XInterruptHandler)My_Handler,&icount);
   XIntc_Connect(&intc,1,(XInterruptHandler)My_Mem_Handler,NULL);

   XIntc_Start(&intc,XIN_REAL_MODE);
   XIntc_Enable(&intc,8);
   XIntc_Enable(&intc,0);
   XIntc_Enable(&intc,1);

   XTmrCtr_SetHandler(&tmrctr,My_Timer,&tcount);
   XTmrCtr_SetOptions(&tmrctr,0,XTC_DOWN_COUNT_OPTION | XTC_INT_MODE_OPTION | XTC_AUTO_RELOAD_OPTION);
   XTmrCtr_SetResetValue(&tmrctr,0,156250000);
   XTmrCtr_Start(&tmrctr,0);

   ssi_printf("Waiting...\n");

   while(1){
      asm("nop");
   }
}

