// Module to generate memories to hold pre-calculated coeficients.
//   input to memory is the state of 2 x's and all the associated y's
//   output is the sum of coefs depending on state of x's and y's
//   memory is loaded with the sums.

module coef
  (sys,  
   rnd_coef,     
   pcie_coef_wr,
   pcie_coef_req,
   ctrl_coef,
   coef_pcie_rd,
   coef_sum
   );
   
`include "params.svh"
`include "structs.svh"
   
   
   input  sys_s       sys;
   input  rnd_coef_s  rnd_coef;
   input  ctrl_coef_s ctrl_coef;
   input  pcie_wr_s   pcie_coef_wr;
   input  pcie_req_s  pcie_coef_req;
      
   output coef_sum_s  coef_sum;
   output pcie_rd_s   coef_pcie_rd;

   wire [MAX_CMEM_DATA:0]    subtotal [0:MAX_CMEM]; // unflopped outputs

   wire [MAX_CMEM_DATA:0]    rd_data;
   
   reg [MAX_CMEM_ADDR:0]     addr [0:MAX_CMEM];
   reg [MAX_CMEM_ADDR:0]     addr_q [0:MAX_CMEM];
   reg [MAX_CMEM_DATA:0]     wdata_q [0:MAX_CMEM];
   reg 			     write_en_q [0:MAX_CMEM];

   reg [MAXXN:0] 	     x;
   reg [MAXYN:0] 	     y;

   wire [MAX_CMEM_SEL:0]     pcie_wr_sel;
   wire [MAX_CMEM_ADDR:0]    pcie_wr_addr;
   
   wire [MAX_CMEM_SEL:0]     pcie_req_sel;
   wire [MAX_CMEM_ADDR:0]    pcie_req_addr;
   
   reg [MAX_RD_TAG:0] 	     req_tag_hold;
   reg [MAX_CMEM_SEL:0]      req_sel_hold;
   reg [MAX_COEF_REQ_PIPE:0] req_pipe;

   reg 			     active_q;
   reg [MAX_RUNS:0] 	     run;
   reg [MAX_RUNS:0] 	     run_q;
   reg [MAX_RUNS:0] 	     run_q2;
   
   genvar 		     mem; //Each mem handles 2 bits, so count = xn/2
   integer 		     xn;
   integer 		     ii;
   
   assign pcie_wr_addr = pcie_coef_wr.addr[ MAX_CMEM_ADDR              : 0];
   assign pcie_wr_sel  = pcie_coef_wr.addr[(MAX_CMEM_ADDR+MAX_CMEM_SEL+1):(MAX_CMEM_ADDR+1)];

   assign pcie_req_addr = pcie_coef_req.addr[ MAX_CMEM_ADDR              : 0];
   assign pcie_req_sel  = pcie_coef_req.addr[(MAX_CMEM_ADDR+MAX_CMEM_SEL+1):(MAX_CMEM_ADDR+1)];
   
   always @ (posedge sys.clk) begin
      if (sys.reset) begin
         x <= 'b0;
         y <= 'b0;
	 active_q <= 1'b0;
	 run      <= 'b0;
      end else begin
         x        <= rnd_coef.x;
         y        <= rnd_coef.y;
	 active_q <= ctrl_coef.active;
	 run      <= rnd_coef.run;
      end
   end
   
   generate
      for (mem=0; mem<=MAX_CMEM; mem = mem+4) begin : VERT       //Vertical bits
         //each loop covers 2 mems, or 4 x's
         //next 4 x's are horizontal
         //then back to vertical etc.

         localparam integer xn = mem*2;
         
         always@(*) begin
            //Top "y" connections
            if (xn < NXCOLS) begin                       //Trim top
               addr[mem]  [0] = 1'b0;
               addr[mem]  [1] = 1'b0;
               addr[mem+1][0] = 1'b0;
               addr[mem+1][1] = 1'b0;
            end else begin
               addr[mem][0]   = y[xn-NXCOLS];
               addr[mem][1]   = y[xn-NXCOLS+1];
               addr[mem+1][0] = y[xn-NXCOLS+2];
               addr[mem+1][1] = y[xn-NXCOLS+3];
            end // else: !if(mem < NXCOLS)

            //Middle connections
            addr[mem][2] = y[xn];
            addr[mem][3] = y[xn+1];
            addr[mem][4] = y[xn+2];
            addr[mem][5] = y[xn+3];

            addr[mem+1][2] = y[xn];
            addr[mem+1][3] = y[xn+1];
            addr[mem+1][4] = y[xn+2];
            addr[mem+1][5] = y[xn+3];

            //Bottom "y" connections
            if (xn+NXCOLS+3 > MAXXN) begin                       //Trim bottom
               addr[mem][6] = 1'b0;
               addr[mem][7] = 1'b0;
               addr[mem+1][6] = 1'b0;
               addr[mem+1][7] = 1'b0;
            end else begin
               addr[mem][6] = y[xn+NXCOLS];
               addr[mem][7] = y[xn+NXCOLS+1];
               addr[mem+1][6] = y[xn+NXCOLS+2];
               addr[mem+1][7] = y[xn+NXCOLS+3];
            end // else: !if(mem < NXCOLS)

            //now, state of 2 x's go into each RAM
            addr[mem][8]   = x[xn];
            addr[mem][9]   = x[xn+1];
            addr[mem+1][8] = x[xn+2];
            addr[mem+1][9] = x[xn+3];
         end // always@ end
      end // block: VERT

      for (mem=2; mem<=MAX_CMEM; mem = mem+4) begin : HORIZ       //Horizontal bits
         //each loop covers 2 mems, or 4 x's
         //next 4 x's are vertical

         localparam integer xn = mem*2;
         
         always@(*) begin
            //left "y" connections
            if ((xn % NXCOLS) < 2) begin                       //Trim left
               addr[mem][0]   = 1'b0;
               addr[mem][1]   = 1'b0;
               addr[mem+1][0] = 1'b0;
               addr[mem+1][1] = 1'b0;
            end else begin
               addr[mem][0]   = y[xn-4];
               addr[mem][1]   = y[xn-3];
               addr[mem+1][0] = y[xn-2];
               addr[mem+1][1] = y[xn-1];
            end // else: !if(mem < NXCOLS)

            //Middle connections
            addr[mem][2] = y[xn];
            addr[mem][3] = y[xn+1];
            addr[mem][4] = y[xn+2];
            addr[mem][5] = y[xn+3];

            addr[mem+1][2] = y[xn];
            addr[mem+1][3] = y[xn+1];
            addr[mem+1][4] = y[xn+2];
            addr[mem+1][5] = y[xn+3];

            //Right "y" connections
            if ((xn % NXCOLS) >= NXCOLS-4) begin                       //Trim right
               addr[mem][6]   = 1'b0;
               addr[mem][7]   = 1'b0;
               addr[mem+1][6] = 1'b0;
               addr[mem+1][7] = 1'b0;
            end else begin
               addr[mem][6]   = y[xn+4];
               addr[mem][7]   = y[xn+5];
               addr[mem+1][6] = y[xn+6];
               addr[mem+1][7] = y[xn+7];
            end // else: !if(mem < NXCOLS)

            //now, state of 2 x's go into each RAM
            addr[mem][8]   = x[xn];
            addr[mem][9]   = x[xn+1];
            addr[mem+1][8] = x[xn+2];
            addr[mem+1][9] = x[xn+3];
         end // always@ end
      end // block: HORIZ

         
      for (mem=0; mem<=MAX_CMEM; mem=mem+1) begin : cmem       //All mems
         
         always @ (posedge sys.clk) begin
            if (sys.reset) begin
               addr_q[mem]      <= 'b0;
               wdata_q[mem]     <= 'b0;
               write_en_q[mem]  <= 'b0;
            end else begin
               if ((pcie_wr_sel == mem) && pcie_coef_wr.vld) begin
                  addr_q[mem]     <= pcie_wr_addr;
                  wdata_q[mem]    <= pcie_coef_wr.data[MAX_CMEM_DATA:0];
                  write_en_q[mem] <= 1'b1;
               end
               else if ((pcie_req_sel == mem) && pcie_coef_req.vld) begin
                  addr_q[mem]     <= pcie_req_addr;
                  wdata_q[mem]    <= 'b0;
		  write_en_q[mem] <= 1'b0;
               end else begin
                  addr_q[mem]     <= addr[mem];
                  wdata_q[mem]    <= 'b0;
                  write_en_q[mem] <= 'b0;
               end // else: !if((pcie_req_sel == mem) && pcie_coef_req.vld)
	    end // else: !if(sys.reset)
	 end // always @ (posedge sys.clk)

	 if (IS_SIM == 0) begin
            coef_mem coef_mem_0
              (
               .ena(~sys.reset),
	       .addra(addr_q[mem]),
               .dina(wdata_q[mem]),
               .douta(subtotal[mem]),
               .wea(write_en_q[mem]),
               .clka(sys.clk)
               );
	 end else begin // if (IS_SIM == 0)
//synthesis translate_off
	    if (mem == MAX_CMEM/2) begin
               coef_mem_alt coef_mem_alt_0
		 (
		  .ena(~sys.reset),
		  .addra(addr_q[mem]),
		  .dina(wdata_q[mem]),
		  .douta(subtotal[mem]),
		  .wea(write_en_q[mem]),
		  .clka(sys.clk)
		  );
	    end // if (mem == 65)

	    else if (mem == 1 + (MAX_CMEM/2)) begin
               coef_mem_inc coef_mem_inc_0
		 (
		  .ena(~sys.reset),
		  .addra(addr_q[mem]),
		  .dina(wdata_q[mem]),
		  .douta(subtotal[mem]),
		  .wea(write_en_q[mem]),
		  .clka(sys.clk)
		  );
	    end // if (mem == 127)

	    else if (mem == MAX_CMEM) begin
               coef_mem_dec coef_mem_dec_0
		 (
		  .ena(~sys.reset),
		  .addra(addr_q[mem]),
		  .dina(wdata_q[mem]),
		  .douta(subtotal[mem]),
		  .wea(write_en_q[mem]),
		  .clka(sys.clk)
		  );
	    end // if (mem == 127)

	    else begin
               coef_mem coef_mem_0
		 (
		  .ena(~sys.reset),
		  .addra(addr_q[mem]),
		  .dina(wdata_q[mem]),
		  .douta(subtotal[mem]),
		  .wea(write_en_q[mem]),
		  .clka(sys.clk)
		  );
	    end // else: !if(mem == 511)
//synthesis translate_on
	 end // else: !if(IS_SIM == 0)
      end // block: MEMS
   endgenerate

   always @ (posedge sys.clk) begin
      if (sys.reset) begin
	 run_q         <= 'b0;
	 run_q2        <= 'b0;
	 coef_sum.run <= 'b0;
	 for (ii=0;ii<=MAX_CMEM;ii=ii+1) begin
            coef_sum.subtotal[ii] <= 'b0;
	 end
      end else begin
	 run_q  <= run;
	 run_q2 <= run_q;  //memory adds coupla clocks
	 coef_sum.run <= run_q2;
	 for (ii=0;ii<=MAX_CMEM;ii=ii+1) begin
	    coef_sum.subtotal[ii] <= subtotal[ii];
         end
      end // else: !if(sys.reset)
   end // always @ (posedge sys.clk)
   
   bigmux
     #(.NBITS(MAX_CMEM_DATA+1),
       .NMUXIN(MAX_CMEM+1),
       .NSEL(MAX_CMEM_SEL+1)
       )
   coef_read_mux
     (
      .clk(sys.clk),
      .reset(sys.reset),
      .data_in(subtotal),
      .sel_in(req_sel_hold),
      .pipe_in(req_pipe[0]),

      .pipe_out(pipe_out),
      .data_out(rd_data)
      );
   	      
   always @ (posedge sys.clk) begin
      if (sys.reset) begin
	 req_pipe       <= 'b0;
	 coef_pcie_rd   <= 'b0;
	 req_tag_hold   <= 'b0;
	 req_sel_hold   <= 'b0;
      end else begin
	 req_pipe <= {req_pipe[MAX_COEF_REQ_PIPE-1:0],pcie_coef_req.vld};
	 if (pcie_coef_req.vld) begin
	    req_tag_hold <= pcie_coef_req.tag;
	    req_sel_hold <= pcie_req_sel;
	 end
	 if (pipe_out) begin
	    coef_pcie_rd.data <= rd_data;
	    coef_pcie_rd.vld  <= 1'b1;
	    coef_pcie_rd.tag  <= req_tag_hold;
	 end else begin
	    coef_pcie_rd <= 'b0;
	 end
      end // else: !if(sys.reset)
   end // always @ (posedge sys.clk)

endmodule // coef


      
