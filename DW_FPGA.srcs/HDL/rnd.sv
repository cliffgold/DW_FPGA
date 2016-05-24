// Module to generate random bits
//   because of the large number of bits to be generated,
//   we use 4 16-bit words, and combine xors of them
//   for the complete x/y vector
//   Their length is 31 bits, so we can go a while before
//   having to switch their seed.

module rnd
  (sys,	 
   pcie_rnd_req,
   ctrl_rnd,
   pick_rnd,
   rnd_pcie_rd,
   rnd_coef
   );
   
`include "params.svh"
`include "structs.svh"
`include "seeds.svh"
   
   input sys_s       sys;
   input 	     pcie_req_s pcie_rnd_req;
   input 	     ctrl_rnd_s ctrl_rnd;
   input 	     pick_rnd_s pick_rnd;
      
   output 	     pcie_rd_s rnd_pcie_rd;
   output 	     rnd_coef_s rnd_coef;

   wire [NQBITS-1:0] rnd_bits;
   reg [NQBITS-1:0]  new_xy [NRUNS-1:0];
   reg [NQBITS-1:0]  old_xy [NRUNS-1:0];
   reg [FLIP_W:0]    flips;
   reg [RUN_W:0]     run;
   reg [RUN_W:0]     run_q;
   reg 		     picked;
   reg 		     enable;

   integer 	     i;
   integer 	     j;
   genvar 	     gi;

   reg [NQBITS-1:0]  shift_bits [FLIP_W:0];
   reg [NQBITS-1:0]  xor_bits [FLIP_W:0];
   reg [NQBITS-1:0]  xor_bits_q [FLIP_W:0];

   pcie_rnd_addr_s    addr_q;
   reg 		      pcie_req_q;
   reg 		      pcie_gotrun;
   reg [RD_TAG_W:0]   tag_q;
   wire		      pipe_out;
   reg [63:0] 	      old_xy_run [0:(NQBITS/64)-1];
   wire [63:0] 	      rd_data;

      
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
	   .EN(1'b1),
	   .SEED_WRITE_EN(1'b0),
	   .SEED(SEED[iter][542:0]),
	   .DATA_OUT(rnd_bits[gi+511:gi])
      );
   end // block: PRBSs
endgenerate

   assign xor_bits[0]   = rnd_bits[NQBITS-1:0];
   assign shift_bits[0] = rnd_bits[NQBITS-1:0];
      
generate
   for (gi=1;gi<=FLIP_W;gi=gi+1) begin :XOR_COMB	 
      
      always@ (*) begin
	 shift_bits[gi] = {shift_bits[gi-1][0],
			   shift_bits[gi-1][NQBITS-1:1]};
	 xor_bits[gi]   = xor_bits[gi-1] & shift_bits[gi];
      end
      
   end // block: XOR_COMB
endgenerate
   
   always@(posedge sys.clk ) begin
      if (sys.reset) begin
	 for (i=0;i<=FLIP_W;i=i+1) begin	 
	    xor_bits_q[i] <= 'b0;
	 end
      end else begin
	 for (i=0;i<=FLIP_W;i=i+1) begin	 
	    xor_bits_q[i] <= xor_bits[i];
	 end
      end
   end // always@ (posedge sys.clk )
   	 
//Pipe 0 - buffer inputs
   always@(posedge sys.clk ) begin
      if (sys.reset) begin
	 run    <= 'b0;
	 run_q  <= 'b0;
	 flips  <= 'b0;
	 picked <= 'b0;
	 enable <= 'b0;
      end else begin
	 run    <= ctrl_rnd.run;
	 run_q  <= run;
	 flips  <= ctrl_rnd.flips;
	 picked <= pick_rnd.pick;
	 enable <= ctrl_rnd.en;
      end
   end // always@ (posedge sys.clk )
   
//Do stuff
   always@(posedge sys.clk ) begin
      if (sys.reset) begin
	 for (i=0;i<NRUNS;i=i+1) begin
	    old_xy[i]  <= 'b0;
	    new_xy[i]  <= 'b0;
	 end
      end else begin
	 if (ctrl_rnd.init) begin
	    old_xy[0] <= rnd_bits;
	 end
	 else if (enable == 1'b1) begin
	    if (picked == 1'b1) begin
	       new_xy[0] <= new_xy[NRUNS-1] ^ xor_bits_q[flips];
	       old_xy[0] <= new_xy[NRUNS-1];
	    end else begin
	       new_xy[0] <= old_xy[NRUNS-1] ^ xor_bits_q[flips];
	       old_xy[0] <= old_xy[NRUNS-1];
	    end
	 end else begin
	    new_xy[0] <= new_xy[NRUNS-1];
	    old_xy[0] <= old_xy[NRUNS-1];
	 end // else: !if(ctrl_rnd.en == 1'b1)
	 
	 for (i=1;i<NRUNS;i=i+1) begin
	    new_xy[i] <= new_xy[i-1];
	    old_xy[i] <= old_xy[i-1];
	 end
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk )

//Now buffer outputs
   always@(posedge sys.clk ) begin
      if (sys.reset) begin
	 rnd_coef    <= 'b0;
      end else begin
	 rnd_coef.x   <= new_xy[0][X_W:0];
	 rnd_coef.y   <= new_xy[0][(X_W*2)+1:X_W+1];
	 rnd_coef.run <= run_q;
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk )


//PCIE read 
   always@(posedge sys.clk ) begin
      if (sys.reset) begin
	 pcie_gotrun <= 'b0;
 	 for (i=0;i<NQBITS/64;i=i+1) begin
 	    old_xy_run[i] <= 'b0;
 	 end
      end else begin
	 if ((addr_q.run == run) && pcie_req_q) begin
	    pcie_gotrun <= 1'b1;
 	    for (i=0;i<NQWORDS;i=i+1) begin
 	       old_xy_run[i]  <= old_xy[NRUNS-1][(i*64)+:64];
 	    end
	 end else begin
	    pcie_gotrun <= 1'b0;
	 end
      end // always@ (posedge sys.clk )
   end // always@ (posedge sys.clk )
          
//pcie - buffer req
   always @ (posedge sys.clk) begin
      if (sys.reset) begin
         addr_q      <= 'b0;
	 pcie_req_q  <= 'b0;
	 tag_q       <= 'b0;
      end else begin
	 if (pcie_rnd_req.vld) begin
            addr_q     <= pcie_rnd_req.addr[MAX_RND_ADDR_S:0];
	    tag_q      <= pcie_rnd_req.tag;
	    pcie_req_q <= 1'b1;
         end 
	 else if(pcie_gotrun) begin
	    pcie_req_q 	<= 1'b0;
	 end
      end // else: !if(sys.reset)
   end // always @ (posedge sys.clk)

   bigmux
     #(.NBITS(64),
       .NMUXIN(NQBITS/64),
       .NFLOPS(2)
       )
   rnd_read_mux
     (
      .clk(sys.clk),
      .reset(sys.reset),
      .data_in(old_xy_run),
      .sel_in(addr_q.addr),
      .pipe_in(pcie_gotrun),

      .pipe_out(pipe_out),
      .data_out(rd_data)
      );
   	      
   always @ (posedge sys.clk) begin
      if (sys.reset) begin
	 rnd_pcie_rd    <= 'b0;
      end else begin
	 if (pipe_out) begin
	    rnd_pcie_rd.data <= rd_data;
	    rnd_pcie_rd.vld  <= 1'b1;
	    rnd_pcie_rd.tag  <= tag_q;;
	 end else begin
	    rnd_pcie_rd <= 'b0;
	 end
      end // else: !if(sys.reset)
   end // always @ (posedge sys.clk)
   
endmodule // rnd

		
