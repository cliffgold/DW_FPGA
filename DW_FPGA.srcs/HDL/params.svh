// Parameters

parameter IS_SIM       = 0;
//coef block 
parameter NROWS        = 16;  //Number of 4x4 structures in a column.  12 for DWAVE-2x
parameter NCOLS        = 16;  //Number of 4x4 structures in a row.     12 for DWAVE-2x

parameter NBITSPERQBIT  = 8;     //Accuracy of coefficients
parameter MAX_CMEM_ADDR = 10-1;  //Max address bit of each coef mem
                                 //2 xbits + 4 shared ybits + 4 ybits
parameter MAX_CMEM_ADDR_BITS = (2 ** (MAX_CMEM_ADDR+1)) - 1;
 
parameter MAX_RUN_BITS  = 19;    //Max number of runs in the same pipe - 1
parameter MAX_RUNS      = $clog2(MAX_RUN_BITS) - 1;

parameter NQBITS        = NROWS * NCOLS * 8;
parameter MAX_QBIT      = $clog2(NQBITS-1) - 1;

 //Bits are divided into planes x and y;
//There are 4 bits in each plane for each 4x4 unit
parameter NXROWS       = NROWS * 4; 
parameter NXCOLS       = NCOLS * 4;


parameter MAX_CMEM      = NROWS*NCOLS*2 -1      ;  //Number of coef mems -1
parameter MAX_CMEM_DATA  = NBITSPERQBIT + 4 - 1  ;  //Number of bits in subtotals
parameter MAX_CMEM_SEL   = $clog2(MAX_CMEM) -1;   //Number of bits in selector

parameter MAXXN        = 2*MAX_CMEM +1    ;  //Number of bits in the x plane -1
parameter MAXYN        = MAXXN           ;  //Number of bits in the y plane -1

                      // 2 x's, 4 crosshatch y's, 4 y's around the edges

parameter MAX_CTRL_MEM_ADDR  = 9;  // 10 address bits on each of the 16 ctrl mems

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
parameter MAX_RD_TAG = 7;
parameter MAX_PCIE_COEF_DATA  = MAX_CMEM_DATA;
parameter MAX_PCIE_COEF_ADDR  = MAX_CMEM_ADDR + MAX_CMEM_SEL + 1;
parameter MAX_PCIE_RND_DATA   = 31;
parameter MAX_PCIE_RND_ADDR   = 8;
parameter MAX_PCIE_CTRL_DATA  = 63;

parameter MAX_SUM             = 23;

//Pipes

parameter MAX_COEF_REQ_PIPE = 2;
parameter MAX_TEMP          = 15;

//prbs
parameter MAX_FLIP          = $clog2(NQBITS) - 2;
parameter MAX_PRBS          = (NQBITS+32-1)/288;
parameter MAX_PRBS_CNT      = $clog2(MAX_PRBS*37);   

//CTRL sequence
parameter CTRL_RND_RUN    = 1;
parameter CTRL_PICK_RUN   = 18;
parameter CTRL_PICK_E_RUN = 16;

parameter COEF_RUN        = 3;
parameter SUM_RUN         = 8;
parameter PICK_RUN        = 0;

   
