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
		  logic [MAX_CMEM_SEL:0]  sel;
		  logic [MAX_CMEM_ADDR:0] addr;
		  }
	       pcie_coef_addr_s;

parameter MAX_COEF_ADDR_S = MAX_CMEM_ADDR + MAX_CMEM_SEL + 1;

typedef struct packed
	       {
		  logic 		      is_cmd;
		  logic [MAX_RUNS:0] 	      run;
		  logic 		      ctrl1;
		  logic [MAX_CTRL_MEM_ADDR:0] addr;
		  }
		 ctrl_addr_s;

parameter MAX_CTRL_ADDR_S = 1 + MAX_RUNS+1 + 1 + MAX_CTRL_MEM_ADDR+1 -1;

typedef struct packed
	       {
		  logic [MAX_RUNS:0] run;
		  logic [MAX_QBIT:0] addr;
		  }
	       pcie_rnd_addr_s;

parameter MAX_RND_ADDR_S = MAX_CMEM_ADDR + MAX_CMEM_SEL + 1;


typedef struct packed
	       {
		  logic               init;
		  logic               en;
		  logic [MAX_RUNS:0]  run;
		  
		  logic [MAX_FLIP:0] flips;
		  }
		 ctrl_rnd_s;

parameter MAX_CTRL_RND_S = 1+1 + (MAX_FLIP+1) +
                           MAX_RUNS+1 -1;

typedef struct packed
	       {
		  logic                 init;
		  logic 		en;
		  logic                 early_en;

		  logic [MAX_TEMP:0]    temperature;
		}
		 ctrl_pick_s;

parameter MAX_CTRL_PICK_S = 2 + MAX_TEMP+1 -1;

typedef struct packed
	       {
		  logic [MAXXN:0]    x;
		  logic [MAXYN:0]    y;
		  logic [MAX_RUNS:0] run;
		}
	       rnd_coef_s;

parameter MAX_RND_COEF_S = MAXXN+1 + MAXYN+1 + MAX_RUNS+1 - 1;

typedef struct packed
	       {
		  logic signed [0:MAX_CMEM] [MAX_CMEM_DATA:0]  subtotal;
		  logic [MAX_RUNS:0] run;
		}
	       coef_sum_s;

parameter MAX_COEF_SUM_S = (MAX_CMEM+1)*(MAX_CMEM_DATA+1) + MAX_RUNS+1 - 1;

typedef struct packed
	       {
		  logic               pick;
		  logic [MAX_RUNS:0]  run;
		  }
		 pick_rnd_s;

parameter MAX_PICK_RND = 1 + MAX_RUNS + 1;

typedef struct packed
	       {
		  logic signed [23:0] full_sum;
		  logic [MAX_RUNS:0]  run;
		  }
		 sum_pick_s;

parameter MAX_SUM_PICK = 24 + MAX_RUNS;

typedef struct packed
	       {
		  logic done;

		  logic [MAX_FLIP:0]   flips;
		  logic [MAX_TEMP:0]   temperature;
		  }
		 ctrl_word1_s;

parameter MAX_CTRL1_WORD_S = 1 + MAX_FLIP+1 + MAX_TEMP+1 -1;

typedef struct packed
	       {
		  logic [31:0] 		    count;
		  }
		 ctrl_word0_s;

parameter MAX_CTRL0_WORD_S = 31;

typedef struct packed
	       {
		  ctrl_word0_s ctrl0;
		  ctrl_word1_s ctrl1;
		  }
		 ctrl_word_s;

parameter MAX_CTRL_WORD_S = MAX_CTRL0_WORD_S + MAX_CTRL1_WORD_S + 1;

typedef struct packed
	       {
		  logic [MAX_RUN_BITS:0] stop;
		  logic [MAX_RUN_BITS:0] start;
		  logic                  init;
		  }
		 ctrl_cmd_s;

parameter MAX_CTRL_CMD_S = MAX_RUN_BITS+1 + MAX_RUN_BITS+1 + 1 -1;
