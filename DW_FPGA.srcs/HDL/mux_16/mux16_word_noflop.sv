// Module to generate any word-size by 16 mux.
//   Words are NBITS wide
//   This instantiates logic, so that optimum slice use is guaranteed
//   per Xilinx xapp522

`include "timescale.svh"

module mux16_word_noflop #(parameter NBITS=12)
  (
   input [NBITS-1:0] data_in [0:15],
   input [3:0]  sel,

   output [NBITS-1:0] data_out
   );
   
   reg [15:0] mux16 [NBITS-1:0];
   
   genvar nbit;
   genvar nword;

   generate
      for (nbit=0;nbit<NBITS;nbit=nbit+1)   begin: MAIN_LOOP
	 
	 for (nword=0;nword<16;nword=nword+1) begin : BIT_SCRAMBLER
	    assign mux16[nbit][nword] = data_in[nword][nbit];
	 end

	 mux16_noflop mux
	   (
	    .data_in(mux16[nbit]),
	    .sel(sel),
	    .data_out(data_out[nbit])
	    );
      end // block: MAIN_LOOP
   endgenerate
endmodule // standard_16word_mux


      
