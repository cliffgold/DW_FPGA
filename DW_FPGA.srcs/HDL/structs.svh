// These structures define all the inter-module interfaces

typedef struct packed
	       {
		  logic reset; //async reset
		  logic clk;
		  }
	       sys_s;

parameter MAX_SYS_S = 2 -1;


typedef struct packed
	       {
		  logic [63:0] data;
		  logic        vld;
		  logic [31:0] addr;
		  }
		 pcie_wr_s;

parameter MAX_PCIE_WR_S = 64 + 1 + 32 -1;

typedef struct packed
	       {
		  logic [63:0]          data;
		  logic                 vld;
		  logic [MAX_RD_TAG:0]  tag;
		  }
		 pcie_rd_s;

parameter MAX_PCIE_RD_S = 64 + 1 + MAX_RD_TAG+1 -1;

typedef struct packed
	       {
		  logic [MAX_RD_TAG:0]  tag;
		  logic 		vld;
		  logic [31:0] 		addr;
		  }
		 pcie_req_s;

parameter MAX_PCIE_REQ_S = MAX_RD_TAG+1 + 1 + 32 -1;


typedef struct packed
	       {
		  logic active;
		  logic init;
		  logic en;
		  }
		 ctrl_coef_s;

parameter MAX_CTRL_COEF_S = 3 -1;

typedef struct packed
	       {
		  logic                   init;
		  logic                   en;
		  logic [MAX_RUN_BITS:0]  run;
		  
		  logic [MAX_FLIP_BITS:0] flips;
		  }
		 ctrl_rnd_s;

parameter MAX_CTRL_RND_S = 1+1 + (MAX_FLIP_BITS+1) +
                           MAX_RUN_BITS+1 -1;

typedef struct packed
	       {
		  logic                  init;
		  logic                  en;

		  logic [0:MAX_RUN] [MAX_TEMP_BITS:0]   temperature;
		  logic [0:MAX_RUN] [MAX_OFFSET_BITS:0] offset;
		}
		 ctrl_pick_s;

parameter MAX_CTRL_PICK_S = 2 + MAX_RUN_BITS+1 +
			    (MAX_RUN+1)*(MAX_TEMP_BITS+1) +
			    (MAX_RUN+1)*(MAX_OFFSET_BITS+1) -1;

typedef struct packed
	       {
		  logic [MAXXN:0]  x;
		  logic [MAXYN:0]  y;
		  logic [MAX_RUN_BITS:0] run;
		}
	       rnd_coef_s;

parameter MAX_RND_COEF_S = MAXXN+1 + MAXYN+1 + MAX_RUN_BITS+1 - 1;

typedef struct packed
	       {
		  logic signed [0:MAX_CMEM] [MAX_CMEM_DATA:0]  subtotal;
		  logic [MAX_RUN_BITS:0] run;
		}
	       coef_sum_s;

parameter MAX_COEF_SUM_S = (MAX_CMEM+1)*(MAX_CMEM_DATA+1) + MAX_RUN_BITS+1 - 1;

typedef struct packed
	       {
		  logic [MAX_RUN:0]      pick;
		  logic [MAX_RUN_BITS:0] run;
		  }
		 pick_rnd_s;

parameter MAX_PICK_RND = MAX_RUN + 1;

typedef struct packed
	       {
		  logic signed [23:0]    full_sum;
		  logic [MAX_RUN_BITS:0] run;
		  }
		 sum_pick_s;

parameter MAX_SUM_PICK = 24 + MAX_RUN_BITS;

typedef struct packed
	       {
		  logic done;

		  logic [MAX_FLIP_BITS:0]   flips;
		  logic [MAX_TEMP_BITS:0]   temperature;
		  logic [MAX_OFFSET_BITS:0] offset;      
		  logic [31:0] 		    count;
		  }
		 ctrl_word_s;

parameter MAX_CTRL_WORD_S = 5 + MAX_FLIP_BITS+1 + NJIGGLE_WORD  -1;

typedef struct packed
	       {
		  logic [MAX_RUN:0] stop;
		  logic [MAX_RUN:0] start;
		  logic             init;
		  }
		 pcie_ctrl_data_s;

parameter MAX_PCIE_CTRL_DATA_S = MAX_RUN+1 + MAX_RUN+1 + 1 -1;
