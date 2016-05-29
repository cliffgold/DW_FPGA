// Parameters

parameter IS_SIM       = 0;
//coef block 
parameter NROWS        = 16;  //Number of 4x4 structures in a column.  12 for DWAVE-2x
parameter NCOLS        = 16;  //Number of 4x4 structures in a row.     12 for DWAVE-2x

parameter NBITSPERQBIT  = 8;     //Accuracy of coefficients
parameter NCMEM_ADDRS   = 1024;
parameter CMEM_ADDR_W   = 10-1;  //Max address bit of each coef mem
                      // 2 x's, 4 crosshatch y's, 4 y's around the edges
parameter NCMEMS        = NROWS*NCOLS*2      ;  //Number of coef mems
parameter CMEM_DATA_W   = NBITSPERQBIT + 4 - 1  ;  //Number of bits in subtotals
parameter CMEM_SEL_W    = $clog2(NCMEMS) -1;   //Number of bits in selector

parameter CTRL_MEM_ADDR_W  = 9;  // 10 address bits on each of the 16 ctrl mems

                                 //2 xbits + 4 shared ybits + 4 ybits
 
parameter NRUNS         = 21;    //Max number of runs in the same pipe
parameter RUN_W         = $clog2(NRUNS) - 1;

parameter NQBITS        = NROWS * NCOLS * 8;
parameter QBIT_W        = $clog2(NQBITS) - 1;
parameter QWORD_W       = QBIT_W - 6; //64 bit words
parameter NQWORDS       = NQBITS/64;

parameter X_W           = 2*NCMEMS -1    ;  //Number of bits in the x plane -1
parameter Y_W           = X_W           ;  //Number of bits in the y plane -1

 //Bits are divided into planes x and y;
//There are 4 bits in each plane for each 4x4 unit
parameter NXROWS       = NROWS * 4; 
parameter NXCOLS       = NCOLS * 4;


//TBD - This is not how BARs really work

parameter COEF_BAR_START = 32'h0000_0000;
parameter COEF_BAR_END   = 32'h1FFF_FFFF;
parameter CTRL_BAR_START = 32'h2000_0000;
parameter CTRL_BAR_END   = 32'h3FFF_FFFF;
parameter RND_BAR_START  = 32'h4000_0000;
parameter RND_BAR_END    = 32'h5FFF_FFFF;
parameter PICK_BAR_START = 32'h6000_0000;
parameter PICK_BAR_END   = 32'h7FFF_FFFF;

//Bit Widths
parameter RD_TAG_W          = 7;
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

//CTRL sequence
parameter CTRL_RND_RUN    = 1;
parameter CTRL_PICK_RUN   = 18;
parameter CTRL_PICK_E_RUN = 16;

parameter COEF_RUN        = 3;
parameter SUM_RUN         = 8;
parameter PICK_RUN        = 0;

   
