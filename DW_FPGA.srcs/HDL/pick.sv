// Module to pick the step to take

module pick
  (sys,	  
   sum_pick,
   ctrl_pick,
   pcie_pick_req,

   pick_pcie_rd,
   pick_rnd
   );

`include "params.svh"
`include "structs.svh"
      
   input sys_s         sys;
   input sum_pick_s    sum_pick;
   input ctrl_pick_s   ctrl_pick;
   input pcie_req_s    pcie_pick_req;

   output pcie_rd_s    pick_pcie_rd;
   output pick_rnd_s   pick_rnd;

   reg signed [NJIGGLE_WORD-1:0] jiggle;
   reg signed [NJIGGLE_WORD-2:0] rnd_bits;

   reg signed [MAX_SUM_BITS:0] 	 old_sum [0:MAX_RUN];
   reg signed [MAX_SUM_BITS:0] 	 old_sum_q;
   reg signed [MAX_SUM_BITS:0] 	 old_sum_j;
   reg signed [MAX_SUM_BITS:0] 	 mult_j;

   reg signed [MAX_SUM_BITS:0] 	 full_sum_q;
   reg signed [MAX_SUM_BITS:0] 	 full_sum_q1;
   reg signed [MAX_SUM_BITS:0] 	 full_sum_q2;

   reg [MAX_RUN_BITS:0] 	 run_q;
   reg [MAX_RUN_BITS:0] 	 run_q1;
   reg [MAX_RUN_BITS:0] 	 run_q2;
   
   prbs_many 
     #(
       .CHK_MODE(0),
       .INV_PATTERN(0),
       .POLY_LENGTH(63),
       .POLY_TAP(62),
       .NBITS(NJIGGLE_WORD-1)
       )
   prbs_63
     (
      .RST(sys.reset),
      .CLK(sys.clk),
      .DATA_IN(63'b0),
      .EN(ctrl_pick.en),
      .SEED_WRITE_EN(ctrl_pick.init),
      .SEED(63'h1BADF00DDEADBEEF),
      .DATA_OUT(rnd_bits)
      );

   always@(posedge sys.clk) begin //Multiplier wants synchronous reset
      if (sys.reset) begin
	 jiggle <= 'b0;
      end else begin
	 if (ctrl_pick.temperature[sum_pick.run] == 'b0) begin
	    jiggle <= 'b0;
	 end else begin
	    jiggle <= (rnd_bits + ctrl_pick.offset[sum_pick.run]) >>> 
		      (NJIGGLE_WORD-ctrl_pick.temperature[sum_pick.run]);
	    old_sum_q <= old_sum[sum_pick.run];
	    mult_j    <= old_sum_q * jiggle;
	    old_sum_j <= (old_sum_q <<< NJIGGLE_WORD) + mult_j;
	 end
	 run_q <= sum_pick.run;
	 run_q1 <= run_q;
	 run_q2 <= run_q1;
	 
	 full_sum_q <= sum_pick.full_sum;
	 full_sum_q1 <= full_sum_q;
	 full_sum_q2 <= full_sum_q1;
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk )

	 
   always@(posedge sys.clk ) begin
      if (sys.reset) begin
	 pick_rnd.pick[MAX_RUN:0]     <= 'b0;
	 pick_rnd.run[MAX_RUN_BITS:0] <= 'b0;
      end else begin
	 pick_rnd.run <= run_q2;
	 if (full_sum_q2 < old_sum_j)   begin
	    old_sum[run_q2] <= full_sum_q2;
	    pick_rnd.pick[run_q2] <= 1'b1;
	 end else begin
	    pick_rnd.pick[run_q2] <= 1'b0;
	 end
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk )
   
   always@(posedge sys.clk ) begin
      if (sys.reset) begin
	 pick_pcie_rd <= 'b0;
      end else begin
	 if (pcie_pick_req.vld) begin
	    pick_pcie_rd.data <= {{64-MAX_RUN_BITS-1-MAX_SUM_BITS-1{1'b0}},
				  run_q2[MAX_RUN_BITS:0],
				  old_sum[pcie_pick_req.addr[MAX_SUM_BITS:0]]};
	    pick_pcie_rd.vld  <= 1'b1;
	    pick_pcie_rd.tag  <= pcie_pick_req.tag;
	 end else begin
	    pick_pcie_rd.vld  <= 1'b0;
	 end
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk )
   
   
endmodule // pick
