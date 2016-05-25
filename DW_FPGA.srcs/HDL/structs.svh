// These structures define all the inter-module interfaces

typedef struct packed
	       {
		  logic reset; //async reset
		  logic clk;
		  }
	       sys_s;

parameter SYS_S_W = 2 -1;


typedef struct packed
	       {
		  logic [63:0] data;
		  logic        vld;
		  logic [31:0] addr;
		  }
		 pcie_wr_s;

parameter PCIE_WR_S_W = 64 + 1 + 32 -1;

typedef struct packed
	       {
		  logic [63:0]          data;
		  logic                 vld;
		  logic [RD_TAG_W:0]  tag;
		  }
		 pcie_rd_s;

parameter PCIE_RD_S_W = 64 + 1 + RD_TAG_W+1 -1;

typedef struct packed
	       {
		  logic [RD_TAG_W:0]  tag;
		  logic 		vld;
		  logic [31:0] 		addr;
		  }
		 pcie_req_s;

parameter PCIE_REQ_S_W = RD_TAG_W+1 + 1 + 32 -1;

typedef struct packed
	       {
		  logic [CMEM_SEL_W:0]  sel;
		  logic [CMEM_ADDR_W:0] addr;
		  }
	       pcie_coef_addr_s;

parameter COEF_ADDR_S_W = CMEM_ADDR_W + CMEM_SEL_W + 1;

typedef struct packed
	       {
		  logic 		      is_cmd;
		  logic [RUN_W:0] 	      run;
		  logic 		      ctrl1;
		  logic [CTRL_MEM_ADDR_W:0] addr;
		  }
		 pcie_ctrl_addr_s;

parameter CTRL_ADDR_S_W = 1 + RUN_W+1 + 1 + CTRL_MEM_ADDR_W+1 -1;

typedef struct packed
	       {
		  logic [RUN_W:0]  run;
		  logic [QWORD_W:0] addr; //-6 because 64 bits per word
		  }
	       pcie_rnd_addr_s;

parameter RND_ADDR_S_W = RUN_W+1 + QWORD_W+1 -1;


typedef struct packed
	       {
		  logic               init;
		  logic               en;
		  logic [RUN_W:0]  run;
		  
		  logic [FLIP_W:0] flips;
		  }
		 ctrl_rnd_s;

parameter CTRL_RND_S_W = 1+1 + (FLIP_W+1) +
                           RUN_W+1 -1;

typedef struct packed
	       {
		  logic                               init;
		  logic [NRUNS-1:0]              en;
		  logic [NRUNS-1:0] [TEMP_W:0] temperature;
		}
		 ctrl_pick_s;

parameter CTRL_PICK_S_W = 1 + NRUNS-1+1 + TEMP_W+1 -1;

typedef struct packed
	       {
		  logic [X_W:0]    x;
		  logic [Y_W:0]    y;
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
		  logic               pick;
		  logic [RUN_W:0]  run;
		  }
		 pick_rnd_s;

parameter MAX_PICK_RND = 1 + RUN_W + 1;

typedef struct packed
	       {
		  logic signed [23:0] full_sum;
		  logic [RUN_W:0]  run;
		  }
		 sum_pick_s;

parameter SUM_W_PICK = 24 + RUN_W;

typedef struct packed
	       {
		  logic next;

		  logic [FLIP_W:0]   flips;
		  logic [TEMP_W:0]   temperature;
		  }
		 ctrl_word1_s;

parameter MAX_CTRL1_WORD_S = 1 + FLIP_W+1 + TEMP_W+1 -1;

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

parameter CTRL_WORD_S_W = MAX_CTRL0_WORD_S + MAX_CTRL1_WORD_S + 1;

typedef struct packed
	       {
		  logic [NRUNS-1:0] stop;
		  logic [NRUNS-1:0] start;
		  logic                  init;
		  }
		 ctrl_cmd_s;

parameter CTRL_CMD_S_W = NRUNS-1+1 + NRUNS-1+1 + 1 -1;
