// Module to generate random bits
//   because of the large number of bits to be generated,
//   we use 4 16-bit words, and combine xors of them
//   for the complete x/y vector
//   Their length is 31 bits, so we can go a while before
//   having to switch their seed.

`include "timescale.svh"

module rnd
  (sys,	 
   pcie_rnd,
   ctrl_rnd,
   pick_rnd,
   rnd_pcie,
   rnd_coef
   );
   
`include "params.svh"
`include "structs.svh"
`include "seeds.svh"
   
   input sys_s       sys;
   input 	     pcie_block_s   pcie_rnd;
   input 	     ctrl_rnd_s     ctrl_rnd;
   input 	     pick_rnd_s     pick_rnd;
      
   output 	     block_pcie_s  rnd_pcie;
   output 	     rnd_coef_s    rnd_coef;

   wire [NQBITS-1:0] rnd_bits;
   reg [NQBITS-1:0]  new_xy_in;
   reg [NQBITS-1:0]  new_xy_out;
   reg [NQBITS-1:0]  old_xy_in;
   reg [NQBITS-1:0]  old_xy_out;

   reg [FLIP_W:0]    flips;
   reg [RUN_W:0]     run;
   reg 		     picked;
   reg 		     enable;

   integer 	     i;
   integer 	     j;
   genvar 	     gi;

   reg [NQBITS-1:0]  shift_bits [0:NFLIPS];
   reg [NQBITS-1:0]  xor_bits   [0:NFLIPS];
   reg [NQBITS-1:0]  xor_bits_q [0:NFLIPS];

   rnd_addr_s        addr_q;
   reg [10:0] 	     len_q;
   
   reg 		     pcie_req_q;
   reg 		     pcie_gotrun;
   wire 	     pipe_out;
   reg [31:0] 	     old_xy_run [0:(NQBITS/32)-1];
   wire [31:0] 	     rd_data;
   
   reg 		     was_init;
   reg 		     init;
         
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
   for (gi=1;gi<NFLIPS;gi=gi+1) begin :XOR_COMB	 
      
      always@ (*) begin
	 shift_bits[gi] = {shift_bits[gi-1][0],
			   shift_bits[gi-1][NQBITS-1:1]};
	 xor_bits[gi]   = xor_bits[gi-1] & shift_bits[gi];
      end
      
   end // block: XOR_COMB
endgenerate
   
   always@(posedge sys.clk ) begin
      if (sys.reset) begin
	 for (i=0;i<NFLIPS;i=i+1) begin	 
	    xor_bits_q[i] <= 'b0;
	 end
      end else begin
	 for (i=0;i<NFLIPS;i=i+1) begin	 
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
	 enable <= 'b0;
      end else begin
	 run    <= ctrl_rnd.run;
	 flips  <= ctrl_rnd.flips;
	 picked <= pick_rnd.pick;
	 enable <= ctrl_rnd.en;
      end
   end // always@ (posedge sys.clk )
   
   always@(posedge sys.clk ) begin
      if (sys.reset) begin
	 was_init <= 1'b0;
	 init     <= 1'b0;
      end else begin
	 if (run == 'b0) begin
	    if (ctrl_rnd.init == 1'b0) begin
	       was_init <= 1'b0;
	       init     <= 1'b0;
	    end else begin
	       if (was_init == 1'b0) begin
		  was_init <= 1'b1;
		  init     <= 1'b1;
	       end else begin
		  init <= 1'b0;
	       end
	    end // else: !if(ctrl_rnd.init == 1'b0)
	 end // if (run == 'b0)
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk )
   
   always@(posedge sys.clk ) begin
      if (sys.reset) begin
	 old_xy_in  <= 'b0;
	 new_xy_in  <= 'b0;
      end else begin
	 if (init) begin
	    old_xy_in <= rnd_bits;
	 end
	 else if (enable == 1'b1) begin
	    if (picked == 1'b1) begin
	       new_xy_in <= new_xy_out ^ xor_bits_q[flips];
	       old_xy_in <= new_xy_out;
	    end else begin
	       new_xy_in <= old_xy_out ^ xor_bits_q[flips];
	       old_xy_in <= old_xy_out;
	    end
	 end else begin
	    new_xy_in <= new_xy_out;
	    old_xy_in <= old_xy_out;
	 end // else: !if(enable == 1'b1)
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk )

generate
   for (gi=0;gi<NQBITS/256;gi++) begin : xy_shift_regs
      localparam XY_INDEX = gi*256;

      c_shift_ram_0 new_xy_0 
	(
	 .D(new_xy_in[XY_INDEX +:256]),     // input wire [255 : 0] D
	 .CLK(sys.clk),                     // input wire CLK
	 .SCLR(sys.reset),                  // input wire SCLR 
	 .Q(new_xy_out[XY_INDEX +:256])  // output wire [255 : 0] Q
	 );
      
      c_shift_ram_0 old_xy_0 
	(
	 .D(old_xy_in[XY_INDEX +:256]),     // input wire [255 : 0] D
	 .CLK(sys.clk),                     // input wire CLK
	 .SCLR(sys.reset),                  // input wire SCLR
	 .Q(old_xy_out[XY_INDEX +:256])  // output wire [255 : 0] Q
	 );
   end // block: xy_shift_regs
endgenerate

//Now buffer outputs
   always@(posedge sys.clk ) begin
      if (sys.reset) begin
	 rnd_coef    <= 'b0;
      end else begin
	 rnd_coef.x   <= new_xy_in[X_W:0];
	 rnd_coef.y   <= new_xy_in[(X_W*2)+1:X_W+1];
	 rnd_coef.run <= (run + RND_COEF_RUN) % NRUNS;
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk )

//PCIE read   
//pcie - buffer req
   always @ (posedge sys.clk) begin
      if (sys.reset) begin
         addr_q      <= 'b0;
	 len_q       <= 'b0;
	 pcie_req_q  <= 'b0;
      end else begin
	 if ((pcie_rnd.vld == 1'b1) &&
	     (pcie_rnd.wr  == 1'b0)) begin
            addr_q     <= pcie_rnd.addr;
	    pcie_req_q <= 1'b1;
	    if (pcie_rnd.len == 'b0) begin
	       len_q   <= 11'b100_0000_0000;
	    end else begin
	       len_q      <= pcie_rnd.len;
	    end
	 end
	 else if(pcie_gotrun) begin
	    if (len_q > 'b1) begin
	       len_q       <= len_q  - 'b1;
	       addr_q.addr <= addr_q.addr + 'd1;
	    end else begin
	       pcie_req_q 	<= 1'b0;
	    end
	 end
      end // else: !if(sys.reset)
   end // always @ (posedge sys.clk)

//Wait for right run to come
   always@(posedge sys.clk ) begin
      if (sys.reset) begin
	 pcie_gotrun <= 'b0;
 	 for (i=0;i<NQBITS/32;i=i+1) begin
 	    old_xy_run[i] <= 'b0;
 	 end
      end else begin
	 if ((addr_q.run  == run)  && 
	     (pcie_req_q  == 1'b1) &&
	     (pcie_gotrun == 1'b0)) begin
	    pcie_gotrun <= 1'b1;
 	    for (i=0;i<NQBITS/32;i=i+1) begin
 	       old_xy_run[i]  <= old_xy_out[(i*32)+:32];
 	    end
	 end else begin
	    pcie_gotrun <= 1'b0;
	 end
      end // always@ (posedge sys.clk )
   end // always@ (posedge sys.clk )
          
   bigmux
     #(.NBITS(32),
       .NMUXIN(NQBITS/32),
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
	 rnd_pcie    <= 'b0;
      end else begin
	 if (pipe_out) begin
	    rnd_pcie.data <= rd_data;
	    rnd_pcie.vld  <= 1'b1;
	 end else begin
	    rnd_pcie <= 'b0;
	 end
      end // else: !if(sys.reset)
   end // always @ (posedge sys.clk)
   
endmodule // rnd

		
 
