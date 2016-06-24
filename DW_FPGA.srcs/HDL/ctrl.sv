// Module to control the 16 runs
`include "timescale.svh"

module ctrl
  (sys,	  
   pcie_ctrl_wr,
   ctrl_rnd,
   ctrl_pick
   );

`include "params.svh"
`include "structs.svh"
      
   input  sys_s          sys;
   input  pcie_ctrl_wr_s pcie_ctrl_wr;
   
   output ctrl_rnd_s     ctrl_rnd;
   output ctrl_pick_s    ctrl_pick;
   
   reg [RUN_W:0]         run;
   reg [NRUNS-1:0]       step;
 
   reg [RUN_W:0]         rnd_run;
   reg [RUN_W:0]         pick_run;

   reg [NRUNS-1:0]         ram_we0;
   reg [NRUNS-1:0]         ram_we1;
   ctrl_word_s             ram_data;
   reg [CTRL_MEM_ADDR_W:0] ram_addr;
   
   wire [NRUNS-1:0] 	   ctrl_busy;

   ctrl_word_s             ctrl_word [0:NRUNS-1];
   ctrl_cmd_s              ctrl_cmd;
   ctrl_cmd_s              ctrl_cmd_q;

   
   integer i;
   genvar  gi;
   
   always@(posedge sys.clk) begin
      if (sys.reset) begin
	 ram_we0  <= 'b0;
	 ram_we1  <= 'b0;
	 ram_addr <= 'b0;
	 ram_data <= 'b0;
	 ctrl_cmd <= 'b0;
	 
      end else begin
	 if (pcie_ctrl_wr.vld) begin  
	    if (pcie_ctrl_wr.addr.is_cmd == 1'b1) begin
	       ram_we0     <= 'b0;
	       ram_we1     <= 'b0;
	       ctrl_cmd    <= pcie_ctrl_wr.data[CTRL_CMD_S_W:0];
	    end
	    else if (pcie_ctrl_wr.addr.is_ctrl0 == 1'b1) begin
	       ram_data.word0 <= pcie_ctrl_wr.data[CTRL_WORD0_S_W:0];
	       ram_addr       <= pcie_ctrl_wr.addr.addr;
	       ram_we0 	      <= {{(NRUNS-1){1'b0}},1'b1} << pcie_ctrl_wr.addr.run;
	       ram_we1        <= 'b0;
	    end else begin
	       ram_data.word1 <= pcie_ctrl_wr.data[CTRL_WORD1_S_W:0];
	       ram_addr       <= pcie_ctrl_wr.addr.addr;
	       ram_we1 	      <= {{(NRUNS-1){1'b0}},1'b1} << pcie_ctrl_wr.addr.run;
	       ram_we0        <= 'b0;
	    end // else: !if(pcie_ctrl_wr.addr.is_ctrl0 == 1'b1)
	    
	 end else begin // if (pcie_ctrl_wr.vld)
	    ram_we0 	   <= 'b0;
	    ram_we1 	   <= 'b0;
	    ctrl_cmd.start <= ctrl_cmd.start & ~ctrl_busy;
	    ctrl_cmd.stop  <= 'b0;
	 end // else: !if(pcie_ctrl_wr.vld)
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk)
      
   always@(posedge sys.clk) begin
      if (sys.reset) begin
	 step       <= 'b0;
	 ctrl_cmd_q <= 'b0;
	 run        <= 'b0;
      end else begin
	 if (run == NRUNS-1) begin
	    run        <= 'b0;
	    step       <= 'b1;
	    ctrl_cmd_q <= ctrl_cmd;
	 end else begin
	    run        <= run + 1;
	    step       <= step << 1'b1;
	 end
      end
   end // always@ (posedge sys.clk)

generate
   for (gi=0;gi<NRUNS;gi=gi+1) begin : CTRL_RAM

      ctrl_onerun ctrl_onerun_0
	  (
	   .sys(sys),
	   .ram_we0(ram_we0[gi]),
	   .ram_we1(ram_we1[gi]),
	   .ram_addr(ram_addr),
	   .ram_data(ram_data),
	   .start(ctrl_cmd_q.start[gi]),
	   .stop(ctrl_cmd_q.stop[gi]),
	   .step(step[gi]),
	   
	   .ctrl_word(ctrl_word[gi]),
	   .ctrl_busy(ctrl_busy[gi])
	   );
   end
endgenerate

   assign rnd_run  = (run + CTRL_RND_RUN)  % NRUNS;
   assign pick_run = (run + CTRL_PICK_RUN) % NRUNS;
   
   always@(posedge sys.clk) begin
      if (sys.reset) begin
	 ctrl_rnd  <= 'b0;
	 ctrl_pick <= 'b0;
      end else begin
	 ctrl_rnd.init   <= ctrl_cmd.init;
	 ctrl_rnd.en     <= ctrl_busy[rnd_run]; 
	 ctrl_rnd.run    <= rnd_run;
	 ctrl_rnd.flips  <= ctrl_word[rnd_run].word0.flips;

	 ctrl_pick.init        <= ctrl_cmd.init;
	 ctrl_pick.en          <= ctrl_busy[pick_run];
	 ctrl_pick.temperature <= ctrl_word[pick_run].word0.temperature;
	 ctrl_pick.cutoff      <= ctrl_word[pick_run].word0.cutoff;
	 ctrl_pick.run         <= pick_run;
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk)
   	 
endmodule // ctrl


   
 
 
