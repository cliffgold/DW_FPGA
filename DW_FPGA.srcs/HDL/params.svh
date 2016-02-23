// Parameters

//coef block 
parameter NROWS        = 16;  //Number of 4x4 structures in a column.  12 for DWAVE-2x
parameter NCOLS        = 16;  //Number of 4x4 structures in a row.     12 for DWAVE-2x

parameter NBITSPERQBIT  = 8;     //Accuracy of coefficients
parameter MAX_CMEM_ADDR = 10-1;  //Max address bit of each coef mem
                                 //2 xbits + 4 shared ybits + 4 ybits 
parameter MAX_RUN       = 15;    //Max number of runs in the same pipe

parameter NQBITS        = NROWS * NCOLS * 8;

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

//TBD - This is not how BARs really work

parameter COEF_BAR_START = 32'h0;
parameter COEF_BAR_END   = 32'h1FFFFF;
parameter CTRL_BAR_START = 32'h200000;
parameter CTRL_BAR_END   = 32'h20ffff;
parameter RND_BAR_START  = 32'h210000;
parameter RND_BAR_END    = 32'h22ffff;
parameter PICK_BAR_START = 32'h230000;
parameter PICK_BAR_END   = 32'h23ffff;

//Bit Widths
parameter MAX_RD_TAG = 7;
parameter MAX_PCIE_COEF_DATA  = MAX_CMEM_DATA;
parameter MAX_PCIE_COEF_ADDR  = MAX_CMEM_ADDR + MAX_CMEM_SEL + 1;
parameter MAX_PCIE_RND_DATA   = 31;
parameter MAX_PCIE_RND_ADDR   = 8;
parameter MAX_PCIE_CTRL_DATA  = 63;
parameter MAX_PCIE_CTRL_ADDR  = 7;

parameter NJIGGLE_WORD        = 24;
parameter MAX_SUM_BITS        = 23;

//Pipes

parameter MAX_COEF_REQ_PIPE = 2;
parameter MAX_RUN_BITS      = $clog2(MAX_RUN) - 1;
parameter MAX_OFFSET_BITS   = 8;
parameter MAX_TEMP_BITS     = 15;

//prbs
parameter MAX_FLIP_BITS     = $clog2(NQBITS) - 2;
   


   
