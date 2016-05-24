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

   reg signed [SUM_W-1:0]      rnd_bits;

   reg signed [SUM_W:0] 	 old_sum [0:NRUNS-1];
   reg signed [SUM_W+2:0] 	 old_sum_j;

   reg signed [SUM_W:0] 	 full_sum_q;
   reg signed [SUM_W:0] 	 full_sum_q1;
   reg signed [SUM_W:0] 	 full_sum_q2;

   reg [RUN_W:0] 		 run_q;
   reg 				 enable_q;

   integer 			 i;
   
   prbs_many 
     #(
       .CHK_MODE(0),
       .INV_PATTERN(0),
       .POLY_LENGTH(63),
       .POLY_TAP(62),
       .NBITS(SUM_W)
       )
   prbs_63
     (
      .RST(sys.reset),
      .CLK(sys.clk),
      .DATA_IN(63'b0),
      .EN(ctrl_pick.en[sum_pick.run]),
      .SEED_WRITE_EN(ctrl_pick.init),
      .SEED(63'h1BADF00DDEADBEEF),
      .DATA_OUT(rnd_bits)
      );

   always@(posedge sys.clk) begin //Multiplier wants synchronous reset
      if (sys.reset | ctrl_pick.init) begin
	 old_sum_j   <=  {1'b0,{SUM_W{1'b1}}};
      end else begin
	 old_sum_j <= $signed(old_sum[sum_pick.run]) + 
		      $signed(rnd_bits & ({SUM_W{1'b1}} >> (SUM_W - ctrl_pick.temperature[sum_pick.run])));
      end // else: !if(sys.reset | ctrl_pick.init)
   end // always@ (posedge sys.clk)
   
   always@(posedge sys.clk) begin
      if (sys.reset) begin
	 run_q         <= 'b0;
	 full_sum_q    <= 'b0;
	 enable_q      <= 'b0;
      end else begin
	 run_q         <= sum_pick.run;
	 full_sum_q    <= sum_pick.full_sum;
	 enable_q      <= ctrl_pick.en[sum_pick.run];
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
	 pick_rnd.run <= (NRUNS+run_q - PICK_RUN)% NRUNS;
	 if (ctrl_pick.init) begin
	    old_sum[run_q] <= {1'b0,{SUM_W{1'b1}}};
	    pick_rnd.pick <= 1'b0;
	 end
	 else if ((full_sum_q < old_sum_j) & enable_q) begin
	    old_sum[run_q] <= full_sum_q;
	    pick_rnd.pick   <= 1'b1;
	 end else begin
	    pick_rnd.pick <= 1'b0;
	 end
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk )
   
   always@(posedge sys.clk ) begin
      if (sys.reset) begin
	 pick_pcie_rd <= 'b0;
      end else begin
	 if (pcie_pick_req.vld) begin
	    pick_pcie_rd.data <= {{64-RUN_W-1-SUM_W-1{1'b0}},
				  run_q[RUN_W:0],
				  old_sum[pcie_pick_req.addr[SUM_W:0]]};
	    pick_pcie_rd.vld  <= 1'b1;
	    pick_pcie_rd.tag  <= pcie_pick_req.tag;
	 end else begin
	    pick_pcie_rd.vld  <= 1'b0;
	 end
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk )
   
   
endmodule // pick
