// Module to control the 16 runs
`include "timescale.svh"

module ctrl
  (sys,	  
   pcie_ctrl,
   ctrl_rnd,
   ctrl_pick
   );

`include "params.svh"
`include "structs.svh"
      
   input  sys_s          sys;
   input  pcie_block_s   pcie_ctrl;
   
   output ctrl_rnd_s     ctrl_rnd;
   output ctrl_pick_s    ctrl_pick;
   
   reg [RUN_W:0]         run;
   reg [NRUNS-1:0]       step;
 
   reg [RUN_W:0]         rnd_run;
   reg [RUN_W:0]         pick_run;

   reg 			 ram_we;
   reg [31:0] 		 ram_data;
   ctrl_addr_s           ram_addr;
   
   wire [NRUNS-1:0] 	   ctrl_busy;

   ctrl_word_s             ctrl_word [0:NRUNS-1];
   ctrl_cmd_s              ctrl_cmd;
   ctrl_cmd_s              ctrl_cmd_tbd;
   ctrl_cmd_s              ctrl_cmd_running;

   reg [1:0] 		   new_cmd;

   ctrl_addr_s             ctrl_addr;
      
   integer i;
   genvar  gi;

   assign ctrl_addr = pcie_ctrl.addr;
   
   always@(posedge sys.clk) begin
      if (sys.reset) begin
	 ram_we   <= 'b0;
	 ram_addr <= 'b0;
	 ram_data <= 'b0;
	 ctrl_cmd <= 'b0;
      end else begin
	 if (pcie_ctrl.vld) begin  
	    if (ctrl_addr.is_cmd == 1'b1) begin
	       ram_we     <= 'b0;
	       if (ctrl_addr.part[0] == 1'b0) begin
		  ctrl_cmd[31:0]            <= pcie_ctrl.data[31:0];
	          new_cmd[0]                <= 'b1;
	          new_cmd[1]                <= 'b0;
	       end else begin
		  ctrl_cmd[CTRL_CMD_S_W:32] <= pcie_ctrl.data[CTRL_CMD_S_W-32:0];
	          new_cmd[1]                <= 'b1;
		  new_cmd[0]                <= 'b0;
	       end
	    end else begin
	       ram_data   <= pcie_ctrl.data;
	       ram_addr   <= ctrl_addr;
	       ram_we     <= 'b1;
	       new_cmd    <= 'b0;
	    end // else: !if(ctrl_addr.is_cmd == 1'b1)
	 end else begin // if (pcie_ctrl.vld)
	    ram_we 	  <= 'b0;
	    new_cmd       <= 'b0;
	 end // else: !if(pcie_ctrl_wr.vld)
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk)
      
   always@(posedge sys.clk) begin
      if (sys.reset) begin
	 step       <= 'b0;
	 run        <= 'b0;
      end else begin
	 if (run == NRUNS-1) begin
	    run        <= 'b0;
	    step       <= 'b1;
	 end else begin
	    run        <= run + 1;
	    step       <= step << 1'b1;
	 end
      end
   end // always@ (posedge sys.clk)

   always@(posedge sys.clk) begin
      if (sys.reset) begin
	 ctrl_cmd_tbd     <= 'b0;
	 ctrl_cmd_running <= 'b0;
      end else begin
	 if (new_cmd[0] == 1) begin
	    ctrl_cmd_tbd[31:0] <=
				  (ctrl_cmd_tbd[31:0]
				   & ~ctrl_cmd_running[31:0])
				   | ctrl_cmd[31:0];

	    ctrl_cmd_tbd[CTRL_CMD_S_W:32] <=
				    ctrl_cmd_tbd[CTRL_CMD_S_W:32]
	                            & ~ctrl_cmd_running[CTRL_CMD_S_W:32];
	    
	 end
	 else if (new_cmd[1] == 1) begin
	    ctrl_cmd_tbd[31:0] <=
				  ctrl_cmd_tbd[31:0]
				  & ~ctrl_cmd_running[31:0];
	    
	    ctrl_cmd_tbd[CTRL_CMD_S_W:32] <=
				  (ctrl_cmd_tbd[CTRL_CMD_S_W:32]
				   & ~ctrl_cmd_running[CTRL_CMD_S_W:32])
				   | ctrl_cmd[CTRL_CMD_S_W:32];
	 end else begin
	    ctrl_cmd_tbd <= ctrl_cmd_tbd & ~ctrl_cmd_running;
	 end
	 				
	 if (run == NRUNS-1) begin
	    if (ctrl_cmd_tbd.init != 'b0) begin
	       ctrl_cmd_running.init  <= ctrl_cmd_tbd.init;
	       ctrl_cmd_running.start <= 'b0;
	       ctrl_cmd_running.stop  <= 'b0;
	    end
	    else if (ctrl_cmd_tbd.start != 'b0) begin
	       ctrl_cmd_running.init  <= 'b0;
	       ctrl_cmd_running.start <= ctrl_cmd_tbd.start;
	       ctrl_cmd_running.stop  <= 'b0;
	    end
	    else if (ctrl_cmd_tbd.stop != 'b0) begin
	       ctrl_cmd_running.init  <= 'b0;
	       ctrl_cmd_running.start <= 'b0;
	       ctrl_cmd_running.stop  <= ctrl_cmd_tbd.stop;
	    end else begin
	       ctrl_cmd_running  <= 'b0;
	    end
	 end // if (run == NRUNS-1)
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk)
   
   generate
      for (gi=0;gi<NRUNS;gi=gi+1) begin : CTRL_RAM
	 
	 ctrl_onerun ctrl_onerun_0
	      (
	       .sys(sys),
	       .ram_whoami(gi[RUN_W:0]),
	       .ram_we(ram_we),
	       .ram_addr(ram_addr),
	       .ram_data(ram_data),
	       .start(ctrl_cmd_running.start[gi]),
	       .stop(ctrl_cmd_running.stop[gi]),
	       .step(step[gi]),
	       
	       .ctrl_word(ctrl_word[gi]),
	       .ctrl_busy(ctrl_busy[gi])
	       );
      end
   endgenerate

   always@(posedge sys.clk) begin
      if (sys.reset) begin
	 rnd_run  = 'b0;
	 pick_run = 'b0;
      end else begin
	 rnd_run  = (run + CTRL_RND_RUN -1)  % NRUNS;
	 pick_run = (run + CTRL_PICK_RUN -1) % NRUNS;
      end
   end
   
   always@(posedge sys.clk) begin
      if (sys.reset) begin
	 ctrl_rnd  <= 'b0;
	 ctrl_pick <= 'b0;
      end else begin
	 ctrl_rnd.init   <= ctrl_cmd_running.init;
	 ctrl_rnd.en     <= ctrl_busy[rnd_run]; 
	 ctrl_rnd.run    <= rnd_run;
	 ctrl_rnd.flips  <= ctrl_word[rnd_run].flips;

	 ctrl_pick.init        <= ctrl_cmd_running.init;
	 ctrl_pick.en          <= ctrl_busy[pick_run];
	 ctrl_pick.temperature <= ctrl_word[pick_run].temperature;
	 ctrl_pick.cutoff      <= ctrl_word[pick_run].cutoff;
	 ctrl_pick.run         <= pick_run;
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk)
   	 
endmodule // ctrl


   
 
 
