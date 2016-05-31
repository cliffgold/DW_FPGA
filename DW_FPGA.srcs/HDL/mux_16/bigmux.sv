// Module to generate any size mux.
//   Words are NBITS wide, and NMUX selected by NSEL of them
//   This instantiates logic, so that optimum slice use is guaranteed
//   per Xilinx xapp522

module bigmux #(
		parameter NBITS=12,     //Word size
                          NMUXIN=576,   //Number of words
		          NFLOPS=2,     //Flop levels.  For example, 2 puts a flop at ~1/3 and ~2/3 of the way
		          NSEL=$clog2(NMUXIN)
		)
  (
   input              clk,
   input              reset,
   input [NBITS-1:0]  data_in [0:NMUXIN-1],
   input [NSEL-1:0]   sel_in,
   input              pipe_in,

   output             pipe_out,
   output [NBITS-1:0] data_out
   );

   localparam NLEVELS = ((NSEL-1)/4) + 1;
   localparam NMUXES0 = ((NMUXIN-1)/16) + 1;
   localparam NLVLPERF = (NLEVELS/(NFLOPS+1))+1;
   
   reg [NBITS-1:0]    mux16_data_in [0:NLEVELS-1][0:NMUXES0][0:15];
   reg  [3:0]         mux16_sel     [0:NLEVELS-1];
   reg  [NBITS-1:0]   selected_word [0:NLEVELS-1] [0:NMUXES0-1]; 

   reg  [NSEL-1:0]    sel_pipe      [0:NLEVELS-1];

   reg [NLEVELS-1:0]  pipe;
  
   integer ii;
   
   genvar mux;
   genvar lvl;
   genvar i;

   generate
      for (lvl=0;lvl<NLEVELS;lvl=lvl+1)             begin : LEVELS
	 for (i=lvl*4;i<lvl*4+4;i=i+1)              begin : PAD_SEL_BITS
            if (i<NSEL) begin
	       if (lvl==0) begin
		  assign mux16_sel[lvl][i-(lvl*4)] = sel_in[i];
	       end else begin
		  assign mux16_sel[lvl][i-(lvl*4)] = sel_pipe[lvl-1][i];
	       end
            end else begin
               assign mux16_sel[lvl][i-(lvl*4)] = 1'b0;
            end
         end
         
         for (mux=0;
              mux<((NMUXIN-1)/(16 << (lvl*4))) + 1;
              mux=mux+1)                           begin : ONE_LEVEL
            
            for (i=mux*16;i<mux*16+16;i=i+1)       begin : PAD_IN_WORDS
               if (i<((NMUXIN-1)/('b1<<(lvl*4)))+1) begin
                  if (lvl == 'b0) begin
                     assign mux16_data_in[lvl][mux][i-mux*16] = data_in[i];
                  end else begin
                     assign mux16_data_in[lvl][mux][i-mux*16] = selected_word[lvl-1][i];
                  end
               end else begin
                  assign mux16_data_in[lvl][mux][i-mux*16] = 'b0;
               end
            end // block: PAD_IN_WORDS
            
	    if ((lvl%NLVLPERF) == (NLVLPERF-1)) begin
               mux16_word_flop
		 #(
                   .NBITS(NBITS)
                   ) 
               word_mux_f_0
		 (
		  .clk(clk),
		  .reset(reset),
		  .data_in(mux16_data_in[lvl][mux][0:15]),
		  .sel(mux16_sel[lvl][3:0]),
		  
		  .data_out(selected_word[lvl][mux])
		  );
	    end else begin // if ((lvl%NLVLPERF) == (NLVLPERF-1))
               mux16_word_noflop
		 #(
                   .NBITS(NBITS)
                   ) 
               word_mux_nf_0
		 (
		  .data_in(mux16_data_in[lvl][mux][0:15]),
		  .sel(mux16_sel[lvl][3:0]),
		  
		  .data_out(selected_word[lvl][mux])
		  );
	    end // else: !if((lvl%NLVLPERF) == (NLVLPERF-1))
	    
         end // block: ONE_LEVEL
      end // block: LEVELS
   endgenerate
   
   assign data_out = selected_word[NLEVELS-1][0];
   
   always @ (posedge clk ) begin
      if (reset) begin
         pipe <= 'b0;
         for (ii=0;ii<NLEVELS;ii=ii+1) begin
            sel_pipe[ii] <= 'b0;
         end
      end else begin
         pipe <= {pipe[NLEVELS-2:0],pipe_in};
         sel_pipe[0] <= sel_in;
         for (ii=1;ii<NLEVELS;ii=ii+1) begin
            sel_pipe[ii] <= sel_pipe[ii-1];
         end
      end // else: !if(reset)
   end // always @ (posedge clk )

   assign pipe_out = pipe[NLEVELS-1];
   

endmodule // bigmux



      
