##################################################################################################

The Static design is the primary .bit file that the FPGA boots into.  
The LedRltA and LedRtlB are two example partial designs that either can programmed into the FPGA after boot.

All three designs are designed for the Xilinx KC705 development board.

These examples are based on Xilinx's UG947 and UG909.  To get the proper background on partial 
reconfiguration, I HIGHLY recommend you read these two user guides 
before going through these below instructions.

# Make the static .bit file
$ cd dev-board-examples/firmware/targets/PartialReconfigurationExample/StaticDesign/
$ make

# Make Partial Design A .bit file
$ cd dev-board-examples/firmware/targets/PartialReconfigurationExample/LedRtlA/
$ make

# Make Partial Design B .bit file
$ cd dev-board-examples/firmware/targets/PartialReconfigurationExample/LedRtlB/
$ make

##################################################################################################

For the static design, the following are characteristics 
in the project build that differ from the standard Vivado Makefile build:

1) A unique name should be used for each reconfigurable RTL module
   For example (refer to StaticDesign Project): LedRtlA and LedRtlB 
   (only two reconfigurable RTL modules in this example)
   
2) Create a "RECONFIG_NAME" export in the Makefile 
   and declare all reconfigurable RTL module
   For example (refer to StaticDesign Project): 
   export RECONFIG_NAME = LedRtlA \
                          LedRtlB      
                          
3) Add a default RTL module for each reconfigurable RTL module in target's ruckus.tcl    
   For example (refer to StaticDesign Project): 
   vhdl work hdl/LedRtlA.vhd
   vhdl work hdl/LedRtlB.vhd   
   
3) Add a default XDC file for each reconfigurable RTL module in target's ruckus.tcl  
   For example (refer to StaticDesign Project):    
   hdl/LedRtlA.xdc
   hdl/LedRtlB.xdc   
   NOTE: These .xdc files can be left blank if the user has no additional constraints
   NOTE: The project .xdc file should be the first file in the target's ruckus.tcl  
   
4) Set the MakeFile target to either "bit_static" or "prom_static"
   For example (refer to StaticDesign Project): 
   target: bit_static
   
5) The top level RTL needs to instantiate the reconfigurable RTL module(s) 
   as "black boxes" (including only the entity declaration of each reconfigurable 
   RTL module(s) at the bottom on the top level RTL)
   For example (refer to StaticDesign Project): 
   See StaticDesign/hdl/StaticDesign.vhd
   
6) The instantiation name of all reconfigurable RTL module(s) needs to follow this
   format: *reconfigurable RTL module name*_Inst
   For example (refer to StaticDesign Project): 
   See StaticDesign/hdl/StaticDesign.vhd
   "LedRtlA_Inst : LedRtlA"

7) The name of each reconfigurable RTL file(s) (.vhd or .v) 
   must match its entity declaration.
   For example (refer to StaticDesign Project): 
   LedRtlA.vhd -> "...entity LedRtlA is..."
   
8) Each reconfigurable RTL module(s) and each static module(s) 
   needs to have its area constraints defined in the top level .xdc file
   For example (refer to StaticDesign Project):    
   Declared at the bottom of StaticDesign/hdl/StaticDesign.xdc
   
#######################################################################################

For the dynamic design(s), the following are characteristics 
in the project build that differ from the standard Vivado Makefile build:
   
1) There is one project for each reconfigurable RTL module 

2) The project name must match the reconfigurable RTL module's
   For example: LedRtlA project matches with StaticDesign's LedRtlA.vhd module 

3) Create a "RECONFIG_CHECKPOINT" export in the Makefile 
   and declare the path to the static design's checkpoint (.dcp) file
   For example (refer to LedRtlA Project): 
   export RECONFIG_CHECKPOINT = $(PROJ_DIR)/../StaticDesign/images/StaticDesign_10000000_static.dcp

4) Set the MakeFile target to "bit_dynamic"
   For example (refer to LedRtlA Project): 
   target: bit_dynamic
   
#######################################################################################