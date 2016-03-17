// Module to generate random bits
//   because of the large number of bits to be generated,
//   we use 4 16-bit words, and combine xors of them
//   for the complete x/y vector
//   Their length is 31 bits, so we can go a while before
//   having to switch their seed.

module rnd
  (sys,	 
   pcie_rnd_wr,
   ctrl_rnd,
   pick_rnd,
   rnd_coef
   );
   
`include "params.svh"
`include "structs.svh"
`include "seeds.svh"
   
   input sys_s        sys;
   input  pcie_wr_s   pcie_rnd_wr;
   input  ctrl_rnd_s  ctrl_rnd;
   input  pick_rnd_s  pick_rnd;
      
   output rnd_coef_s  rnd_coef;

   wire [NQBITS-1:0]      rnd_bits;
   reg [NQBITS-1:0] 	  new_xy [MAX_RUN_BITS:0];
   reg [NQBITS-1:0] 	  old_xy [MAX_RUN_BITS:0];
   reg [MAX_FLIP_BITS:0]  flips;
   reg [MAX_RUNS:0] 	  run;
   reg [MAX_RUNS:0] 	  was_run;
   reg 			  picked;
   
   integer     i;

   genvar      gi;

   reg [NQBITS-1:0] shift_bits [MAX_FLIP_BITS:0];
   reg [NQBITS-1:0] xor_bits   [MAX_FLIP_BITS:0];
   reg [NQBITS-1:0] xor_bits_q [MAX_FLIP_BITS:0];

generate
   for(gi=0;gi<NQBITS;gi=gi+512) begin : PRBS

      localparam iter = gi/512;

      prbs_many
	  #(
	    .CHK_MODE(0),
	    .INV_PATTERN(0),
	    .POLY_LENGTH(543),
	    .POLY_TAP(527),
	    .NBITS(512)
	    )
      prbs_543
	  (
	   .RST(sys.reset),
	   .CLK(sys.clk),
	   .DATA_IN('b0),
	   .EN(ctrl_rnd.en),
	   .SEED_WRITE_EN(ctrl_rnd.init),
	   .SEED(SEED[iter][542:0]),
	   .DATA_OUT(rnd_bits[gi+511:gi])
      );
   end // block: PRBSs
endgenerate

   assign xor_bits[0]   = rnd_bits[NQBITS-1:0];
   assign shift_bits[0] = rnd_bits[NQBITS-1:0];
      
generate
   for (gi=1;gi<=MAX_FLIP_BITS;gi=gi+1) begin :XOR_COMB	 
      
      always@ (*) begin
	 shift_bits[gi] = {shift_bits[gi-1][0],
			   shift_bits[gi-1][NQBITS-1:1]};
	 xor_bits[gi]   = xor_bits[gi-1] & shift_bits[gi];
      end
      
   end // block: XOR_COMB
endgenerate
   
   always@(posedge sys.clk ) begin
      if (sys.reset) begin
	 for (i=0;i<=MAX_FLIP_BITS;i=i+1) begin	 
	    xor_bits_q[i] <= 'b0;
	 end
      end else begin
	 for (i=0;i<=MAX_FLIP_BITS;i=i+1) begin	 
	    xor_bits_q[i] <= xor_bits[i];
	 end
      end
   end // always@ (posedge sys.clk )
   	 
//Pipe 0 - buffer inputs
   always@(posedge sys.clk ) begin
      if (sys.reset) begin
	 run    <= 'b0;
	 flips  <= 'b0;
	 picked <= 'b0;
      end else begin
	 run    <= ctrl_rnd.run;
	 flips  <= ctrl_rnd.flips;
	 picked <= pick_rnd.pick[ctrl_rnd.run];
      end
   end // always@ (posedge sys.clk )
   
//Do stuff
   always@(posedge sys.clk ) begin
      if (sys.reset) begin
	 for (i=0;i<=MAX_RUN_BITS;i=i+1) begin
	    old_xy[i]  <= 'b0;
	    new_xy[i]  <= 'b0;
	 end
	 was_run   <= 'b0;
      end else begin
	 was_run    <= run;
	 if (ctrl_rnd.en == 'b0) begin
	    old_xy[0] <= rnd_bits;
	 end
	 else if (picked == 1'b1) begin
	    new_xy[0] <= new_xy[MAX_RUNS] ^ xor_bits_q[flips];
	    old_xy[0] <= new_xy[MAX_RUNS];
	 end else begin
	    new_xy[0] <= old_xy[MAX_RUNS] ^ xor_bits_q[flips];
	 end
	 for (i=1;i<=MAX_RUNS;i=i+1) begin
	    new_xy[i] <= new_xy[i-1];
	    old_xy[i] <= old_xy[i-1];
	 end
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk )

//Now buffer outputs
   always@(posedge sys.clk ) begin
      if (sys.reset) begin
	 rnd_coef  <= 'b0;
      end else begin
	 rnd_coef.x   <= new_xy[0][MAXXN:0];
	 rnd_coef.y   <= new_xy[0][(MAXXN*2)+1:MAXXN+1];
	 rnd_coef.run <= was_run;
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk )

endmodule // rnd

		
