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
   rnd_coef
   );
   
`include "params.svh"
`include "structs.svh"
   
   input sys_s      sys;
   input pcie_wr_s  pcie_rnd_wr;
   input ctrl_rnd_s ctrl_rnd;
   
   output rnd_coef_s rnd_coef;

   reg  [47:0]   seed [0:3];
   wire [15:0]   prbs_out [0:3];
   reg           seed_write_en;
   integer       i;
   integer       j;
   
   always@(posedge sys.clk or posedge sys.reset) begin
      if (sys.reset) begin
	 seed_write_en  <= 1'b0;
	 seed[0]        <= 'h1;
	 seed[1]        <= 'h2;
	 seed[2]        <= 'h3;
	 seed[3]        <= 'h4;
      end else begin
	 seed_write_en  <= pcie_rnd_wr.vld || ctrl_rnd.init;
	 if (pcie_rnd_wr.vld) begin
	    seed[pcie_rnd_wr.addr[1:0]] <= pcie_rnd_wr.data[47:0];
	 end
      end
   end // always@ (posedge sys.clk or posedge sys.reset)

//Yes, I do know how to spell LENGTH
   PRBS_ANY 
     #(
       .CHK_MODE(0),
       .INV_PATTERN(0),
       .POLY_LENGHT(29),
       .POLY_TAP(27),
       .NBITS(POLY_WORD)
       )
   prbs_29
     (
      .RST(sys.reset),
      .CLK(sys.clk),
      .DATA_IN({POLY_WORD{1'b0}}),
      .EN(ctrl_rnd.en),
      .SEED_WRITE_EN(seed_write_en),
      .SEED(seed[0][28:0]),
      .DATA_OUT(prbs_out[0])
      );

   PRBS_ANY 
     #(
       .CHK_MODE(0),
       .INV_PATTERN(0),
       .POLY_LENGHT(31),
       .POLY_TAP(28),
       .NBITS(POLY_WORD)
       )
   prbs_31
     (
      .RST(sys.reset),
      .CLK(sys.clk),
      .DATA_IN({POLY_WORD{1'b0}}),
      .EN(ctrl_rnd.en),
      .SEED_WRITE_EN(seed_write_en),
      .SEED(seed[1][30:0]),
      .DATA_OUT(prbs_out[1])
      );

   PRBS_ANY 
     #(
       .CHK_MODE(0),
       .INV_PATTERN(0),
       .POLY_LENGHT(41),
       .POLY_TAP(38),
       .NBITS(POLY_WORD)
       )
   prbs_41
     (
      .RST(sys.reset),
      .CLK(sys.clk),
      .DATA_IN({POLY_WORD{1'b0}}),
      .EN(ctrl_rnd.en),
      .SEED_WRITE_EN(seed_write_en),
      .SEED(seed[2][40:0]),
      .DATA_OUT(prbs_out[2])
      );

   PRBS_ANY 
     #(
       .CHK_MODE(0),
       .INV_PATTERN(0),
       .POLY_LENGHT(47),
       .POLY_TAP(42),
       .NBITS(POLY_WORD)
       )
   prbs_47
     (
      .RST(sys.reset),
      .CLK(sys.clk),
      .DATA_IN({POLY_WORD{1'b0}}),
      .EN(ctrl_rnd.en),
      .SEED_WRITE_EN(seed_write_en),
      .SEED(seed[3][46:0]),
      .DATA_OUT(prbs_out[3])
      ); 

   always@(posedge sys.clk or negedge sys.reset) begin
      if (sys.reset) begin
	 for (i=0;i<NQBITS;i=i+1) begin
	   rnd_bit[i] <= 'b0;
	 end
      end else begin
	 for (j=0;j<14;j=j+1) begin	    
	    for (i=0;i<NQBITS;i=i+1) begin
	       rnd_bit[j][i] <= 
		   prbs_out[0][ i                      % POLY_WORD] ^
		   prbs_out[1][(i + i/POLY_WORD)       % POLY_WORD] ^
		   prbs_out[2][(i + i/POLY_WORD_SQ)]   % POLY_WORD] ^
		   prbs_out[3][(i + i/POLY_WORD_CU + j)% POLY_WORD];
	    end
	 end
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk or negedge sys.reset)
   
   always @(*) begin
      xor_bits[0] = rnd_bit[0];
      for (j=0;j<=MAX_FLIP_FRACTION;j=j+1) begin
	 xor_bits[j+1] = xor_bits[j] & rnd_bit[j];
      end
   end
      
   always@(posedge sys.clk or negedge sys.reset) begin
      if (sys.reset) begin
      end else begin
	 for (j=0;j<=MAX_FLIP_FRACTION;j=j+1) begin
	    xor_bits_q[j] <= xor_bits[j];
	 end
	 if (run==MAX_RUN) begin
	    run <= 'b0;
	 end else begin
	    run <= run + 1'b1;
	 end
	 if (decider.update[run] == 1'b1) begin
	    new_xy[run] <= new_xy[run] ^ xor_bits_q[decider.flip_fraction];
	 end else begin
	    new_xy[run] <= old_xy[run] ^ xor_bits_q[decider.flip_fraction];
	 end
	 rnd_coef.x <= new_xy[next_run][MAXXN:0];
	 rnd_coef.y <= new_xy[next_run][(MAXXN*2)+1:MAXXN+1];
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk or negedge sys.reset)

endmodule // rnd

		
