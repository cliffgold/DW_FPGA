// Parameters

parameter IS_SIM       = 0;

parameter CLK_IN_PERIOD  = 10;
parameter SYS_CLK_PERIOD = 4;

parameter NROWS        = 16;  //Number of 4x4 structures in a column.  12 for DWAVE-2x
parameter NCOLS        = 16;  //Number of 4x4 structures in a row.     12 for DWAVE-2x

parameter NBITSPERQBIT  = 8;     //Accuracy of coefficients
parameter NCMEM_ADDRS   = 1024;
parameter CMEM_ADDR_W   = 10-1;  //Max address bit of each coef mem
                      // 2 x's, 4 crosshatch y's, 4 y's around the edges
parameter NCMEMS        = NROWS*NCOLS*2      ;  //Number of coef mems
parameter CMEM_DATA_W   = NBITSPERQBIT + 4 - 1  ;  //Number of bits in subtotals
parameter CMEM_SEL_W    = $clog2(NCMEMS) -1;   //Number of bits in selector

parameter CTRL_MEM_ADDR_W  = 9 -1;  // 9 address bits on each of the 16 ctrl mems

                                 //2 xbits + 4 shared ybits + 4 ybits
 
parameter NRUNS         = 21;    //Max number of runs in the same pipe
parameter RUN_W         = $clog2(NRUNS) - 1;

parameter NQBITS        = NROWS * NCOLS * 8;
parameter QBIT_W        = $clog2(NQBITS) - 1;
parameter QWORD_W       = QBIT_W - 5; //32 bit words

parameter X_W           = 2*NCMEMS -1    ;  //Number of bits in the x plane -1
parameter Y_W           = X_W           ;  //Number of bits in the y plane -1

 //Bits are divided into planes x and y;
//There are 4 bits in each plane for each 4x4 unit
parameter NXROWS       = NROWS * 4; 
parameter NXCOLS       = NCOLS * 4;


//BARs

parameter COFFEE_BAR      = 8'b00000001;  //coef
parameter NOSE_BAR        = 8'b00000010;  //pick
parameter RANDY_BAR       = 8'b00000100;  //rnd
parameter FREAK_BAR       = 8'b00001000;  //ctrl

//Bit Widths
parameter PCIE_COEF_DATA_W  = CMEM_DATA_W;
parameter PCIE_COEF_ADDR_W  = CMEM_ADDR_W + CMEM_SEL_W + 1;
parameter PCIE_RND_DATA_W   = 31;
parameter PCIE_RND_ADDR_W   = 8;

parameter SUM_W             = 23;

//Pipes
parameter NCOEF_REQ_PIPE  = 3;

parameter TEMP_W          = 15;
parameter NFLIPS          = 16;
parameter FLIP_W          = $clog2(NFLIPS) -1;

//Run Pipeline.  Note there is -2 included in each step for input/output sync
parameter CTRL_RND_RUN    = NRUNS - 1;
parameter RND_COEF_RUN    = NRUNS - 1;
parameter COEF_SUM_RUN    = NRUNS - 3;
parameter SUM_PICK_RUN    = NRUNS - 8;
parameter PICK_RND_RUN    = NRUNS - 1;

parameter CTRL_PICK_RUN   = (  CTRL_RND_RUN
			     + RND_COEF_RUN-2 
			     + COEF_SUM_RUN-2 
			     + SUM_PICK_RUN-2) % NRUNS;


//PCIE
parameter LANE_W          = 4-1;
parameter AXI_W           = 64-1;
parameter AXI_BE_W        = ((AXI_W+1)/8)-1;
parameter TYPE_MEM        = 5'b0;
parameter TYPE_CPL        = 5'b01010;

parameter OK              = 3'b000;
parameter UNSUPP          = 3'b001;
parameter CABORT          = 3'b100;

			    
