// Module to generate memories to hold pre-calculated coeficients.
//   input to memory is the state of 2 x's and all the associated y's
//   output is the sum of coefs depending on state of x's and y's
//   memory is loaded with the sums.

module coef
  (sys,  
   rnd_coef,     
   pcie_coef_wr,
   pcie_coef_req,
   coef_pcie_rd,
   coef_sum
   );
   
`include "params.svh"
`include "structs.svh"
   
   
   input  sys_s       sys;
   input  rnd_coef_s  rnd_coef;
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

   reg [MAX_X:0] 	     x;
   reg [MAX_Y:0] 	     y;

   reg [MAX_RD_TAG:0] 	     req_tag_hold;
   reg [MAX_CMEM_SEL:0]      req_sel_hold;
   reg [MAX_COEF_REQ_PIPE:0] req_pipe;

   reg 			     active_q;
   reg [MAX_RUNS:0] 	     run;
   
   genvar 		     mem;
   
   integer 		     xh;
   integer 		     xv;
   integer                   imem;
   integer 		     vmem;
   integer 		     hmem;
   integer 		     ii;
   
   pcie_wr_s                 pcie_coef_wr_q;
   pcie_req_s                pcie_coef_req_q;

   pcie_coef_addr_s          pcie_wr_addr;
   pcie_coef_addr_s          pcie_req_addr;
   
   assign pcie_wr_addr  = pcie_coef_wr_q.addr;
   assign pcie_req_addr = pcie_coef_req_q.addr;
   
   always @ (posedge sys.clk) begin
      if (sys.reset) begin
         pcie_coef_wr_q  <= 'b0;
         pcie_coef_req_q <= 'b0;
      end else begin
         pcie_coef_wr_q  <=  pcie_coef_wr;
         pcie_coef_req_q <=  pcie_coef_req;
      end
   end

   always @ (posedge sys.clk) begin
      if (sys.reset) begin
         x   <= 'b0;
         y   <= 'b0;
	 run <= 'b0;
      end else begin
         x        <= rnd_coef.x;
         y        <= rnd_coef.y;
	 run      <= rnd_coef.run;
      end
   end
   
   always@(*) begin
      for (imem=0; imem<=MAX_CMEM; imem = imem+4) begin : mem_conn
         if ((((imem/2) + (imem/NXCOLS))%2) == 0) begin
	    vmem = imem;
	    xv   = vmem*2;
	    hmem = imem+2;
	    xh   = hmem*2;
	 end else begin
	    vmem = imem+2;
	    xv   = vmem*2;
	    hmem = imem;
	    xh   = hmem*2;
	 end // else: !if((((imem/2) + (imem/NXCOLS))%2) == 0)
	 
         //each loop covers 4 mems, or 8 x's
         //The alternation between Horiz and Vertical X is not simple
         //since each row starts with the opposite phase

	 //VERTICAL first   
         //Top "y" connections
         if (xv < NXCOLS) begin                       //Trim top
	    addr[vmem]  [0] = 1'b0;
	    addr[vmem]  [1] = 1'b0;
	    addr[vmem+1][0] = 1'b0;
	    addr[vmem+1][1] = 1'b0;
         end else begin
	    addr[vmem][0]   = y[xv-NXCOLS];
	    addr[vmem][1]   = y[xv-NXCOLS+1];
	    addr[vmem+1][0] = y[xv-NXCOLS+2];
	    addr[vmem+1][1] = y[xv-NXCOLS+3];
         end // else: !if(vmem < NXCOLS)
	 
         //Middle connections
         addr[vmem][2] = y[xv];
         addr[vmem][3] = y[xv+1];
         addr[vmem][4] = y[xv+2];
         addr[vmem][5] = y[xv+3];
	 
         addr[vmem+1][2] = y[xv];
         addr[vmem+1][3] = y[xv+1];
         addr[vmem+1][4] = y[xv+2];
         addr[vmem+1][5] = y[xv+3];
	 
         //Bottom "y" connections
         if (xv+NXCOLS+3 > MAX_X) begin                       //Trim bottom
	    addr[vmem][6] = 1'b0;
	    addr[vmem][7] = 1'b0;
	    addr[vmem+1][6] = 1'b0;
	    addr[vmem+1][7] = 1'b0;
         end else begin
	    addr[vmem][6] = y[xv+NXCOLS];
	    addr[vmem][7] = y[xv+NXCOLS+1];
	    addr[vmem+1][6] = y[xv+NXCOLS+2];
	    addr[vmem+1][7] = y[xv+NXCOLS+3];
         end // else: !if(vmem < NXCOLS)
	 
         //now, state of 2 x's go into each RAM
         addr[vmem][8]   = x[xv];
         addr[vmem][9]   = x[xv+1];
         addr[vmem+1][8] = x[xv+2];
         addr[vmem+1][9] = x[xv+3];
	 
	 //HORIZ
         //left "y" connections 
         if ((xh % NXCOLS) < 2) begin //Trim left
	    addr[hmem][0]   = 1'b0;
            addr[hmem][1]   = 1'b0;
	    addr[hmem+1][0] = 1'b0;
	    addr[hmem+1][1] = 1'b0;
         end else begin
	    addr[hmem][0]   = y[xh-4];
	    addr[hmem][1]   = y[xh-3];
	    addr[hmem+1][0] = y[xh-2];
	    addr[hmem+1][1] = y[xh-1];
         end // else: !if(hmem < NXCOLS)
	 
         //Middle connections
         addr[hmem][2] = y[xh];
         addr[hmem][3] = y[xh+1];
         addr[hmem][4] = y[xh+2];
         addr[hmem][5] = y[xh+3];
	 
         addr[hmem+1][2] = y[xh];
         addr[hmem+1][3] = y[xh+1];
         addr[hmem+1][4] = y[xh+2];
         addr[hmem+1][5] = y[xh+3];
	 
         //Right "y" connections
         if ((xh % NXCOLS) >= NXCOLS-4) begin                       //Trim right
	    addr[hmem][6]   = 1'b0;
	    addr[hmem][7]   = 1'b0;
	    addr[hmem+1][6] = 1'b0;
	    addr[hmem+1][7] = 1'b0;
         end else begin
	    addr[hmem][6]   = y[xh+4];
	    addr[hmem][7]   = y[xh+5];
	    addr[hmem+1][6] = y[xh+6];
	    addr[hmem+1][7] = y[xh+7];
         end // else: !if(hmem < NXCOLS)
	 
         //now, state of 2 x's go into each RAM
         addr[hmem][8]   = x[xh];
         addr[hmem][9]   = x[xh+1];
         addr[hmem+1][8] = x[xh+2];
         addr[hmem+1][9] = x[xh+3];
      end // block: mem_conn
   end // always@ (*)
      
   generate
      for (mem=0; mem<=MAX_CMEM; mem=mem+1) begin : cmem       //All mems
         
         always @ (posedge sys.clk) begin
            if (sys.reset) begin
               addr_q[mem]      <= 'b0;
               wdata_q[mem]     <= 'b0;
               write_en_q[mem]  <= 'b0;
            end else begin
               wdata_q[mem] <= pcie_coef_wr_q.data[MAX_CMEM_DATA:0];
               if (pcie_coef_wr_q.vld) begin
                  addr_q[mem]  <= pcie_wr_addr.addr;
		  if (mem == pcie_wr_addr.sel) begin
                     write_en_q[mem] <= 1'b1;
		  end else begin
                     write_en_q[mem] <= 1'b0;
		  end
	       end
	       
               else if (pcie_coef_req_q.vld) begin
                  addr_q[mem]  <= pcie_req_addr.addr;
                  write_en_q[mem] <= 1'b0;
               end 

	       else begin
                  addr_q[mem]     <= addr[mem];
                  write_en_q[mem] <= 'b0;
               end // else: !if((pcie_req_sel == mem) && pcie_coef_req.vld)
	    end // else: !if(sys.reset)
	 end // always @ (posedge sys.clk)

         coef_mem coef_mem_0
           (
            .ena(~sys.reset),
	    .addra(addr_q[mem]),
            .dina(wdata_q[mem]),
            .douta(subtotal[mem]),
            .wea(write_en_q[mem]),
            .clka(sys.clk)
            );
      end // block: cmem
   endgenerate

   always @ (posedge sys.clk) begin
      if (sys.reset) begin
	 coef_sum.run <= 'b0;
	 for (ii=0;ii<=MAX_CMEM;ii=ii+1) begin
            coef_sum.subtotal[ii] <= 'b0;
	 end
      end else begin
	 coef_sum.run <= (MAX_RUN_BITS+1+run -COEF_RUN)%(MAX_RUN_BITS+1);
	 for (ii=0;ii<=MAX_CMEM;ii=ii+1) begin
	    coef_sum.subtotal[ii] <= subtotal[ii];
         end
      end // else: !if(sys.reset)
   end // always @ (posedge sys.clk)
   
   bigmux
     #(.NBITS(MAX_CMEM_DATA+1),
       .NMUXIN(MAX_CMEM+1),
       .NFLOPS(2)
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
	 req_pipe <= {req_pipe[MAX_COEF_REQ_PIPE-1:0],pcie_coef_req_q.vld};
	 if (pcie_coef_req_q.vld) begin
	    req_tag_hold <= pcie_coef_req_q.tag;
	    req_sel_hold <= pcie_req_addr.sel;
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


      
