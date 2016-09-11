// Module to pick old vs new better

`include "timescale.svh"

module pick
  (sys,	  
   sum_pick,
   ctrl_pick,
   pcie_pick,

   pick_pcie,
   pick_rnd
   );

`include "params.svh"
`include "structs.svh"
      
   input sys_s            sys;
   input 		  sum_pick_s      sum_pick;
   input 		  ctrl_pick_s     ctrl_pick;
   input 		  pcie_block_s    pcie_pick;

   output 		  block_pcie_s   pick_pcie;
   output 		  pick_rnd_s     pick_rnd;

   reg signed [SUM_W:0]   rnd_bits;

   reg [TEMP_W:0] 	  temperature;
   
   reg signed [SUM_W:0]   old_sum [0:NRUNS-1];
   reg signed [SUM_W:0]   old_sum_q;
   reg signed [SUM_W+2:0] old_sum_j;
   reg signed [SUM_W:0]   cutoff;
   
   reg signed [SUM_W:0]   full_sum;
   reg signed [SUM_W:0]   full_sum_q;

   reg [RUN_W:0] 	  run;
   reg [RUN_W:0] 	  run_q;

   reg 			  enable;
   reg 			  enable_q;

   reg [9:0] 		  length;
   reg [RUN_W:0] 	  address;
   
   integer 		  i;
   
   prbs_many 
     #(
       .CHK_MODE(0),
       .INV_PATTERN(0),
       .POLY_LENGTH(63),
       .POLY_TAP(62),
       .NBITS(SUM_W+1)
       )
   prbs_63
     (
      .RST(sys.reset),
      .CLK(sys.clk),
      .DATA_IN({SUM_W+1{1'b0}}),
      .EN(ctrl_pick.en),
      .SEED_WRITE_EN(ctrl_pick.init),
      .SEED(63'h1BADF00DDEADBEEF),
      .DATA_OUT(rnd_bits)
      );

   always@(posedge sys.clk) begin //Multiplier wants synchronous reset
      if (sys.reset | ctrl_pick.init) begin
         old_sum_q   <= 'b0;
	 old_sum_j   <= {1'b0,{SUM_W{1'b1}}};
         temperature <= 'b0;
	 cutoff      <= {1'b1,{SUM_W{1'b0}}};
      end else begin
	 old_sum_j   <= $signed(old_sum_q) + 
		        $signed(rnd_bits & ({SUM_W{1'b1}} >> (SUM_W - temperature)));
	 old_sum_q   <= old_sum[sum_pick.run];
	 temperature <= ctrl_pick.temperature;
	 cutoff      <= ctrl_pick.cutoff;
      end // else: !if(sys.reset | ctrl_pick.init)
   end // always@ (posedge sys.clk)
   
   always@(posedge sys.clk) begin
      if (sys.reset) begin
	 run        <= 'b0;
	 full_sum   <= 'b0;
	 enable     <= 'b0;
	 
	 run_q      <= 'b0;
	 enable_q   <= 'b0;
	 full_sum_q <= 'b0;
      end else begin
	 run        <= sum_pick.run;
	 full_sum   <= sum_pick.full_sum;
	 enable     <= ctrl_pick.en;
	 
	 run_q      <= run;
	 enable_q   <= enable;
	 if (full_sum > cutoff) begin
	    full_sum_q <= full_sum;
	 end else begin
	    full_sum_q <= cutoff;
	 end
      end // else: !if(sys.reset | ctrl_pick.init)
   end // always@ (posedge sys.clk)
	 
   always@(posedge sys.clk ) begin
      if (sys.reset) begin
	 pick_rnd.pick <= 'b0;
	 pick_rnd.run  <= 'b0;
	 for (i=0;i<NRUNS;i=i+1) begin
	    old_sum[i] <= {1'b0,{SUM_W{1'b1}}};
	 end
      end else begin
	 pick_rnd.run <= (run + PICK_RND_RUN)% NRUNS;
	 if (ctrl_pick.init) begin
	    old_sum[run_q]  <= {1'b0,{SUM_W{1'b1}}};
	    pick_rnd.pick   <= 1'b0;
	 end
	 else if ((full_sum_q < old_sum_j) & enable_q) begin
	    old_sum[run_q]  <= full_sum_q;
	    pick_rnd.pick   <= 1'b1;
	 end else begin
	    pick_rnd.pick   <= 1'b0;
	 end
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk )
   
   always@(posedge sys.clk ) begin
      if (sys.reset) begin
	 pick_pcie <= 'b0;
	 length    <= 'b0;
	 address   <= 'b0;
      end else begin
	 if ((pcie_pick.vld == 1'b1) &&
	     (pcie_pick.wr  == 1'b0)) begin
	    address <= pcie_pick.addr;
	    if (pcie_pick.len == 'b0) begin
	       length  <= 11'b100_0000_0000;
	    end else begin
	       length  <= pcie_pick.len;
	    end
	 end
	 else if (length > 'b0) begin	    
	    pick_pcie.data <= old_sum[address];
	    pick_pcie.vld  <= 1'b1;
	    length         <= length - 'b1;
	    address        <= address + 'd4;
	 end else begin
	    pick_pcie      <= 'b0;
	 end
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk )
   
   
endmodule // pick
