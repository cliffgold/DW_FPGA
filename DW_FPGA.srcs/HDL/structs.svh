// These structures define all the inter-module interfaces

typedef struct packed
	       {
		  logic reset;
		  logic clk;
		  }
	       sys_s;

parameter SYS_S_W = 2 -1;

// PCIe Structures
typedef struct packed
	       {
		  logic [15:0] reqid;
		  logic [7:0]  tag;
		  logic [3:0]  last_be;
		  logic [3:0]  first_be;
		  }
		 pcie_mem_dw1_s;

parameter PCIE_MEM_DW1_S_W = 32 -1;

typedef struct packed
	       {
		  logic       nc_prefix;
		  logic       wdat;
		  logic       dw4;
		  logic [4:0] typ;
		  logic       nc3;
		  logic [2:0] nc_tc;
		  logic       nc2;
		  logic       nc_attr2;
		  logic       nc1;
		  logic       nc_th;
		  logic       nc_td;
		  logic       nc_ep;
		  logic [1:0] nc_attr10;
		  logic [1:0] nc_at;
		  logic [9:0] len;
		  }
		 pcie_std_dw0_s;

parameter PCIE_STD_DW0_S_W = 32 -1;

typedef struct packed
	       {
		  pcie_mem_dw1_s  w1;
		  pcie_std_dw0_s  w0;
		  }
		 pcie_hdr_s;

parameter PCIE_HDR_S_W = 32 -1;

typedef struct packed
	       {
		  logic [31:0] data;
		  logic [31:2] addr;  //Note this is a DW address
		  logic [1:0]  nc_byte;
		  }
		 pcie_qw1_s;

parameter PCIE_QW1_S_W = 64 -1;

typedef struct packed
	       {
		  logic [7:0] bn;
		  logic [4:0] dn;
		  logic [2:0] fn;
		  }
		 pcie_cpl_id_s;

parameter PCIE_CPL_ID_S_W = 8 + 5 + 3 -1;

typedef struct packed
	       {
		  pcie_cpl_id_s id;
		  logic [2:0]   stat;
		  logic 	nc0;
 		  logic [11:2] 	cnt;
		  logic [1:0] 	nc_byte;
		  }
		 pcie_cpl_dw1_s;

parameter PCIE_CPL_DW1_S_W = 32 -1;

typedef struct packed
	       {
		  pcie_cpl_dw1_s  w1;
		  pcie_std_dw0_s  w0;
		  }
		 pcie_cpl_qw0_s;

parameter PCIE_CPL_QW0_S_W = 64 -1;

typedef struct packed
	       {
		  logic [15:0] reqid;
		  logic [7:0]  tag;
		  logic        nc0;
		  logic [6:2]  low_addr;
		  logic [1:0]  nc_byte;
		  }
		 pcie_cpl_dw2_s;


parameter PCIE_CPL_DW2_S = 32 -1;


//AXI interface structures
typedef struct packed
	       {
		  logic [5:0]   buf_av;
		  logic         tready;
		  }
		 axi_tx_out_s;

parameter AXI_TX_OUT_S_W = 2 -1;

typedef struct packed
	       {
		  logic [AXI_W:0]    tdata;
		  logic [AXI_BE_W:0] tkeep;
		  logic [3:0]        tuser;
		  logic 	     tlast;
		  logic 	     tvalid;	     
		  }
		 axi_tx_in_s;

parameter AXI_TX_IN_S_W = AXI_W+1 + AXI_BE_W+1 + 4 + 2  -1;


typedef struct packed
	       {
		  logic         rx_np_req;
		  logic         rx_np_ok;
		  logic         tready;
		  }
		 axi_rx_in_s;

parameter AXI_RX_IN_S_W = 2 -1;

typedef struct packed
	       {
		  logic [11:0]       unused;
		  logic [7:0]        bar;
		  logic              err_poison;
		  logic              err_crc;
		  }
		 axi_rx_tuser;

parameter AXI_RX_TUSER_S_W = 12 + 8 + 2 -1;


typedef struct packed
	       {
		  logic [AXI_W:0]    tdata;
		  logic [AXI_BE_W:0] tkeep;
		  axi_rx_tuser       tuser;
		  logic 	     tlast;
		  logic 	     tvalid;	     
		  }
		 axi_rx_out_s;

parameter AXI_RX_OUT_S_W = AXI_W+1 + AXI_BE_W+1 + 4 + 2  -1;

//Generic PCIE <-> any BLOCK structure
typedef struct packed
	       {
		  logic        vld;
		  logic        wr;
		  logic [31:0] data;
		  logic [31:2] addr;
		  logic [9:0]  len;
		  }
	       pcie_block_s;

parameter PCIE_BLOCKS_S_W = 1 + 1 + 32 + 32 + 10 -1;


typedef struct packed
	       {
		  logic 	     vld;
		  logic [31:0]	     data;
		  }
	       block_pcie_s;

parameter BLOCK_PCIE_S_W = 1 + 32 -1;

// PCIE -> COEF structures
typedef struct packed
	       {
		  logic [CMEM_SEL_W:0]  sel;
		  logic [CMEM_ADDR_W:0] addr;
		  }
	       coef_addr_s;

parameter COEF_ADDR_S_W = CMEM_ADDR_W + CMEM_SEL_W + 1;

// Rnd PCIE structures

typedef struct packed
	       {
		  logic [RUN_W:0]   run;
		  logic [QWORD_W:0] addr;
		  }
	       rnd_addr_s;

parameter RND_ADDR_S_W = RUN_W+1 + QWORD_W+1 -1;


// Ctrl PCIE structures 
typedef struct packed
	       {
		  logic 		    is_cmd;
		  logic [RUN_W:0] 	    run;
		  logic [CTRL_MEM_ADDR_W:0] addr;
		  logic [1:0]               part;
		  }
		 ctrl_addr_s;

parameter CTRL_ADDR_S_W = 1 + RUN_W+1 + 1 + CTRL_MEM_ADDR_W+1 -1;

typedef struct packed
	       {
		  logic [FLIP_W:0] flips;
		  logic [TEMP_W:0] temperature;
		  logic [SUM_W:0]  cutoff;
		  logic            next;
		  logic [31:0] 	   count;
		  }
		 ctrl_word_s;

parameter CTRL_WORD_S_W = FLIP_W+1 + TEMP_W+1 + SUM_W+1 + 1 + 32 -1;

typedef struct packed
	       {
		  logic [NRUNS-1:0] start;
		  logic [NRUNS-1:0] stop;
		  logic             init;
		  }
		 ctrl_cmd_s;

parameter CTRL_CMD_S_W = NRUNS + NRUNS + 1 -1;

//block-block interfaces
typedef struct packed
	       {
		  logic 	    init;
		  logic 	    en;
		  logic [RUN_W:0]   run;
		  
		  logic [FLIP_W:0]  flips;
		  }
		 ctrl_rnd_s;

parameter CTRL_RND_S_W = 1 + 1 + RUN_W+1 + FLIP_W+1 -1;

typedef struct packed
	       {
		  logic            init;
		  logic 	   en;
		  logic [TEMP_W:0] temperature;
		  logic [SUM_W:0]  cutoff;
		  logic [RUN_W:0]  run;
		}
		 ctrl_pick_s;

parameter CTRL_PICK_S_W = 1 + 1 + TEMP_W+1 + SUM_W+1 -1;

typedef struct packed
	       {
		  logic [X_W:0]   x;
		  logic [Y_W:0]   y;
		  logic [RUN_W:0] run;
		}
	       rnd_coef_s;

parameter RND_COEF_S_W = X_W+1 + Y_W+1 + RUN_W+1 - 1;

typedef struct packed
	       {
		  logic signed [0:NCMEMS-1] [CMEM_DATA_W:0]  subtotal;
		  logic [RUN_W:0] run;
		}
	       coef_sum_s;

parameter COEF_SUM_S_W = (NCMEMS)*(CMEM_DATA_W+1) + RUN_W+1 - 1;

typedef struct packed
	       {
		  logic            pick;
		  logic [RUN_W:0]  run;
		  }
		 pick_rnd_s;

parameter PICK_RND_S_W = 1 + RUN_W + 1 - 1;

typedef struct packed
	       {
		  logic signed [SUM_W:0] full_sum;
		  logic        [RUN_W:0] run;
		  }
		 sum_pick_s;

parameter SUM_W_PICK = 23+1 + RUN_W+1 -1;

