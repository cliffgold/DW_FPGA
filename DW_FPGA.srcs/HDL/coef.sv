// Module to generate memories to hold pre-calculated coeficients.
//   input to memory is the state of 2 x's and all the associated y's
//   output is the sum of coefs depending on state of x's and y's
//   memory is loaded with the sums.

`include "timescale.svh"

module coef
  (sys,  
   rnd_coef,     
   pcie_coef,
   coef_pcie,
   coef_sum
   );
   
`include "params.svh"
`include "structs.svh"
   
   
   input  sys_s            sys;
   input  rnd_coef_s       rnd_coef;
   input  pcie_block_s     pcie_coef;
      
   output coef_sum_s       coef_sum;
   output block_pcie_s     coef_pcie;

   wire [CMEM_DATA_W:0]    subtotal [0:NCMEMS-1]; // unflopped outputs

   wire [CMEM_DATA_W:0]    rd_data;
   
   reg [CMEM_ADDR_W:0] 	   addr [0:NCMEMS-1];
   reg [CMEM_ADDR_W:0] 	   addr_q [0:NCMEMS-1];
   reg [CMEM_DATA_W:0] 	   wdata_q;
   reg 			   write_en_q [0:NCMEMS-1];

   reg [X_W:0] 		   x;
   reg [Y_W:0] 		   y;

   reg [CMEM_SEL_W:0]  	    req_sel_hold;
   reg [NCOEF_REQ_PIPE-1:0] req_pipe;
   wire 		    pipe_out;
   
   reg 			   active_q;
   reg [RUN_W:0] 	   run;
   
   genvar 		   mem;
   
   integer 		   xh;
   integer 		   xv;
   integer 		   imem;
   integer 		   vmem;
   integer 		   hmem;
   integer 		   ii;
   
   coef_addr_s             coef_addr;

   assign coef_addr = pcie_coef.addr;
      
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
      for (imem=0; imem<NCMEMS; imem = imem+4) begin : mem_conn
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
         if (xv+NXCOLS+3 > X_W) begin                       //Trim bottom
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
      
   always @ (posedge sys.clk) begin
      if (sys.reset) begin
         wdata_q     <= 'b0;
      end else begin
         if (pcie_coef.vld) begin
            wdata_q <= pcie_coef.data[CMEM_DATA_W:0];
	 end
      end
   end

   generate
      for (mem=0; mem<NCMEMS; mem=mem+1) begin : cmem       //All mems
         
         always @ (posedge sys.clk) begin
            if (sys.reset) begin
               addr_q[mem]      <= 'b0;
               write_en_q[mem]  <= 'b0;
            end else begin
	       write_en_q[mem] <= 1'b0;  //Default case
	       if (pcie_coef.vld) begin
		  addr_q[mem]  <= coef_addr.addr;
		  if (pcie_coef.wr &&
		      mem == coef_addr.sel) begin
		     write_en_q[mem] <= 1'b1;
		  end
	       end else begin
                  addr_q[mem]     <= addr[mem];
	       end
	    end // else: !if(sys.reset)
	 end // always @ (posedge sys.clk)

         coef_mem coef_mem_0
           (
            .ena(~sys.reset),
	    .addra(addr_q[mem]),
            .dina(wdata_q),
            .douta(subtotal[mem]),
            .wea(write_en_q[mem]),
            .clka(sys.clk)
            );
      end // block: cmem
   endgenerate

   always @ (posedge sys.clk) begin
      if (sys.reset) begin
	 coef_sum.run <= 'b0;
	 for (ii=0;ii<NCMEMS;ii=ii+1) begin
            coef_sum.subtotal[ii] <= 'b0;
	 end
      end else begin
	 coef_sum.run <= (run + COEF_SUM_RUN) % NRUNS;
	 for (ii=0;ii<NCMEMS;ii=ii+1) begin
	    coef_sum.subtotal[ii] <= subtotal[ii];
         end
      end // else: !if(sys.reset)
   end // always @ (posedge sys.clk)
   
   bigmux
     #(.NBITS(CMEM_DATA_W+1),
       .NMUXIN(NCMEMS),
       .NFLOPS(NCOEF_REQ_PIPE)
       )
   coef_read_mux
     (
      .clk(sys.clk),
      .reset(sys.reset),
      .data_in(subtotal),
      .sel_in(req_sel_hold),
      .pipe_in(req_pipe[2]),

      .pipe_out(pipe_out),
      .data_out(rd_data)
      );
   	      
   always @ (posedge sys.clk) begin
      if (sys.reset) begin
	 req_pipe       <= 'b0;
	 coef_pcie      <= 'b0;
	 req_sel_hold   <= 'b0;
      end else begin
	 req_pipe <= {req_pipe[NCOEF_REQ_PIPE-2:0],pcie_coef.vld};
	 if (pcie_coef.vld) begin
	    req_sel_hold <= coef_addr.sel;
	 end
	 if (pipe_out) begin
	    coef_pcie.data <= rd_data;
	    coef_pcie.vld  <= 1'b1;
	 end else begin
	    coef_pcie      <= 'b0;
	 end
      end // else: !if(sys.reset)
   end // always @ (posedge sys.clk)

endmodule // coef


      
