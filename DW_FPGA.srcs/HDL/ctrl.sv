// Module to control the 16 runs

module ctrl
  (sys,	  
   pcie_ctrl_wr,
   ctrl_rnd,
   ctrl_pick
   );

`include "params.svh"
`include "structs.svh"
      
   input   sys_s     sys;
   input   pcie_wr_s pcie_ctrl_wr;
   
   output  ctrl_rnd_s  ctrl_rnd;
   output  ctrl_pick_s ctrl_pick;
   
   reg [MAX_RUNS:0] 	   run [0:MAX_RUN_BITS];
   reg [MAX_RUN_BITS:0]    step;
 
   reg [MAX_RUN_BITS:0]      ram_we;
   ctrl_word_s               ram_data;
   reg [MAX_CTRL_MEM_ADDR:0] ram_addr;
   
   wire [MAX_RUN_BITS:0]     ctrl_busy;

   ctrl_word_s    ctrl_word [0:MAX_RUN_BITS];
   ctrl_cmd_s     ctrl_cmd;
   ctrl_cmd_s     ctrl_cmd_q;

   pcie_ctrl_addr_s  address;
   
   
   integer              i;
   genvar 		gi;
   
   assign address = pcie_ctrl_wr.addr;
   
   always@(posedge sys.clk) begin
      if (sys.reset) begin
	 ram_we   <= 'b0;
	 ram_addr <= 'b0;
	 ram_data <= 'b0;
	 ctrl_cmd <= 'b0;
	 
      end else begin
	 if (pcie_ctrl_wr.vld) begin  
	    if (address.is_cmd == 1'b0) begin
	       if (address.ctrl1 == 1'b0) begin
		  ram_data.ctrl0 <= pcie_ctrl_wr.data[MAX_CTRL0_WORD_S:0];
	       end else begin
		  ram_data.ctrl1 <= pcie_ctrl_wr.data[MAX_CTRL1_WORD_S:0];
		  ram_addr 	 <= address.addr;
		  ram_we 	 <= 16'b1 << address.run;
	       end
	    end else begin
	       ram_we    <= 'b0;
	       ctrl_cmd  <= pcie_ctrl_wr.data[MAX_CTRL_CMD_S:0];
	    end // else: !if(pcie_ctrl_wr.addr[MAX_RUN_BITS+11] == 1'b0)
	 end else begin // if (pcie_ctrl_wr.vld)
	    ram_we 	   <= 1'b0;
	    ctrl_cmd.start <= ctrl_cmd.start & ~ctrl_busy;
	    ctrl_cmd.stop  <= 'b0;
	 end // else: !if(pcie_ctrl_wr.vld)
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk)
      
   always@(posedge sys.clk) begin
      if (sys.reset) begin
	 step       <= 'b0;
	 ctrl_cmd_q <= 'b0;
	 for (i=0;i<=MAX_RUN_BITS;i=i+1) begin
	    run[i] <= 'b0;
	 end
      end else begin
	 if (run[0] == MAX_RUN_BITS) begin
	    run[0]     <= 'b0;
	    step       <= 'b1;
	    ctrl_cmd_q <= ctrl_cmd;
	 end else begin
	    run[0] <= run[0] + 1;
	    step   <= step << 1'b1;
	 end
	 for (i=1;i<=MAX_RUN_BITS;i=i+1) begin
	    run[i] <= run[i-1];
	 end
      end
   end // always@ (posedge sys.clk)

generate
   for (gi=0;gi<=MAX_RUN_BITS;gi=gi+1) begin : CTRL_RAM

      ctrl_onerun ctrl_onerun_0
	  (
	   .sys(sys),
	   .ram_we(ram_we[gi]),
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

   always@(posedge sys.clk) begin
      if (sys.reset) begin
	 ctrl_rnd  <= 'b0;
	 ctrl_pick <= 'b0;
      end else begin
	 ctrl_rnd.init  <= ctrl_cmd.init;
	 ctrl_rnd.en    <= ctrl_busy[run[CTRL_RND_RUN]]; 
	 ctrl_rnd.run   <= run[CTRL_RND_RUN];
	 ctrl_rnd.flips <= ctrl_word[run[CTRL_RND_RUN]].ctrl1.flips;

	 ctrl_pick.init        <= ctrl_cmd.init;
	 ctrl_pick.en          <= ctrl_busy[MAX_RUN_BITS:0];
	 for (i=0;i<=MAX_RUN_BITS;i=i+1) begin
	    ctrl_pick.temperature[i] <= ctrl_word[i].ctrl1.temperature;
	 end
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk)
   	 
endmodule // ctrl


   
 
 
