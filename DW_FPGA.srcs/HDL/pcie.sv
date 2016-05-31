// Module to interface to the future Xilinx PCIE block
//   Currently, it is just a shell for simulation 

module pcie
  (sys,
   sys_in,
   bus_pcie_wr,
   bus_pcie_req,
   pcie_bus_rd,

   coef_pcie_rd,
   pick_pcie_rd, 
   rnd_pcie_rd,
  
   pcie_coef_wr,
   pcie_ctrl_wr,
  
   pcie_coef_req,
   pcie_pick_req,
   pcie_rnd_req
   );
   
`include "params.svh"
`include "structs.svh"
   
   input  sys_s      sys;
   input  sys_s      sys_in;

   input  pcie_wr_s  bus_pcie_wr;
   input  pcie_req_s bus_pcie_req;
   output pcie_rd_s  pcie_bus_rd;
   
   input  coef_pcie_rd_s  coef_pcie_rd;
   input  pick_pcie_rd_s  pick_pcie_rd;
   input  rnd_pcie_rd_s   rnd_pcie_rd;
   
   output pcie_coef_wr_s  pcie_coef_wr;
   output pcie_ctrl_wr_s  pcie_ctrl_wr;

   output pcie_coef_req_s pcie_coef_req;
   output pcie_pick_req_s pcie_pick_req;
   output pcie_rnd_req_s  pcie_rnd_req;

   reg    pcie_req_busy;
   reg    pcie_req_busy_clr;

   pcie_wr_s  bus_pcie_wr_q;
   pcie_req_s bus_pcie_req_q;
   pcie_rd_s  pcie_bus_rd_q;
   
//sync 100 MHz IO with 200 MHz system clock
//Note that these are locked together
   resync resync_0
     (
      .sys(sys),
      .sys_in(sys_in),

      .bus_pcie_wr(bus_pcie_wr),
      .bus_pcie_wr_q(bus_pcie_wr_q),

      .bus_pcie_req(bus_pcie_req),
      .bus_pcie_req_q(bus_pcie_req_q),

      .pcie_bus_rd_q(pcie_bus_rd_q),
      .pcie_bus_rd(pcie_bus_rd)
      );
   

//write interface
   always@(posedge sys.clk) begin
      if (sys.reset) begin
         pcie_coef_wr    <= 'b0;
         pcie_ctrl_wr    <= 'b0;
      end else begin // if (sys.reset)
         if (bus_pcie_wr_q.vld) begin 
            if ((bus_pcie_wr_q.addr >= COEF_BAR_START) &&
                (bus_pcie_wr_q.addr <= COEF_BAR_END)) begin
            
               pcie_coef_wr.data <= bus_pcie_wr_q.data;
               pcie_coef_wr.addr <= bus_pcie_wr_q.addr;
               pcie_coef_wr.vld  <= 1'b1;
               pcie_ctrl_wr.vld  <= 1'b0;
            end
            else if ((bus_pcie_wr_q.addr >= CTRL_BAR_START) &&
                     (bus_pcie_wr_q.addr <= CTRL_BAR_END)) begin

               pcie_ctrl_wr.data <= bus_pcie_wr_q.data;
               pcie_ctrl_wr.addr <= bus_pcie_wr_q.addr;
               pcie_coef_wr.vld  <= 1'b0;
               pcie_ctrl_wr.vld  <= 1'b1;
            end
	 end else begin
            pcie_coef_wr.vld <= 1'b0;
            pcie_ctrl_wr.vld <= 1'b0;
         end
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk)
   
//Read Request interface
   always@(posedge sys.clk) begin
      if (sys.reset) begin
         pcie_coef_req   <= 'b0;
         pcie_pick_req   <= 'b0;
	 pcie_rnd_req    <= 'b0;
	 pcie_req_busy   <= 1'b0;
      end else begin // if (sys.reset)
         if (bus_pcie_req_q.vld) begin 
            if ((bus_pcie_req_q.addr >= COEF_BAR_START) &&
                (bus_pcie_req_q.addr <= COEF_BAR_END)   &&
		(pcie_req_busy   == 1'b0)) begin
            
               pcie_coef_req.tag  <= bus_pcie_req_q.tag;
               pcie_coef_req.addr <= bus_pcie_req_q.addr;
               pcie_coef_req.vld  <= 1'b1;
               pcie_req_busy      <= 1'b1;
            end
            else if ((bus_pcie_req_q.addr >= PICK_BAR_START) &&
                     (bus_pcie_req_q.addr <= PICK_BAR_END)) begin

               pcie_pick_req.tag  <= bus_pcie_req_q.tag;
               pcie_pick_req.addr <= bus_pcie_req_q.addr;
               pcie_pick_req.vld  <= 1'b1;
               pcie_req_busy      <= 1'b1;
            end
            else if ((bus_pcie_req_q.addr >= RND_BAR_START) &&
                     (bus_pcie_req_q.addr <= RND_BAR_END)) begin

               pcie_rnd_req.tag  <= bus_pcie_req_q.tag;
               pcie_rnd_req.addr <= bus_pcie_req_q.addr;
               pcie_rnd_req.vld  <= 1'b1;
               pcie_req_busy      <= 1'b1;
            end
	 end else begin // if (bus_pcie_req_q.vld)
	    pcie_coef_req.vld <= 1'b0;
            pcie_pick_req.vld <= 1'b0;
	    pcie_rnd_req.vld  <= 1'b0;
	 end // else: !if(bus_pcie_req_q.vld)
	 if (pcie_req_busy_clr) begin
	    pcie_req_busy     <= 1'b0;
         end
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk)
   
	 
//Read Response interface
   always@(posedge sys.clk) begin
      if (sys.reset) begin
         pcie_bus_rd_q     <= 'b0;
	 pcie_req_busy_clr <= 1'b0;
      end else begin
	 if (pcie_req_busy && !pcie_req_busy_clr) begin
	    if (coef_pcie_rd.vld) begin
	       pcie_bus_rd_q.tag  <= coef_pcie_rd.tag;
	       pcie_bus_rd_q.data <= coef_pcie_rd.data;
	       pcie_bus_rd_q.vld  <= 1'b1;
	       pcie_req_busy_clr  <= 1'b1;
	       
	    end
	    else if (pick_pcie_rd.vld) begin
	       pcie_bus_rd_q.tag  <= pick_pcie_rd.tag;
	       pcie_bus_rd_q.data <= pick_pcie_rd.data;
	       pcie_bus_rd_q.vld  <= 1'b1;
	       pcie_req_busy_clr  <= 1'b1;
	    end
	    else if (rnd_pcie_rd.vld) begin
	       pcie_bus_rd_q.tag  <= rnd_pcie_rd.tag;
	       pcie_bus_rd_q.data <= rnd_pcie_rd.data;
	       pcie_bus_rd_q.vld  <= 1'b1;
	       pcie_req_busy_clr  <= 1'b1;
	    end else begin
	       pcie_bus_rd_q.vld  <= 1'b0;
	       pcie_req_busy_clr  <= 1'b0;
	    end
	 end else begin // if (pcie_req_busy && ~pcie_req_busy_clr)
	    pcie_bus_rd_q.vld  <= 1'b0;
	    pcie_req_busy_clr  <= 1'b0;
	 end // else: !if(pcie_req_busy && ~pcie_req_busy_clr)
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk)
   
endmodule // pcie

     
