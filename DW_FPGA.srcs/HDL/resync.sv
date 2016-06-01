//Module to move between input clk and system clk
//Assumes the two clocks are synced, and system clk freq = 2x input clk freq

`include "timescale.svh"

module resync
  (
   sys,
   sys_in,
   bus_pcie_wr,
   bus_pcie_wr_q,
   bus_pcie_req,
   bus_pcie_req_q,
   pcie_bus_rd_q,
   pcie_bus_rd
   );

`include "params.svh"
`include "structs.svh"
   
   input  sys_s      sys;
   input  sys_s      sys_in;

   input  pcie_wr_s  bus_pcie_wr;
   input  pcie_req_s bus_pcie_req;
   output pcie_rd_s  pcie_bus_rd;
   
   output pcie_wr_s  bus_pcie_wr_q;
   output pcie_req_s bus_pcie_req_q;
   input  pcie_rd_s  pcie_bus_rd_q;

   pcie_wr_s  bus_pcie_wr_buf;
   pcie_req_s bus_pcie_req_buf;
   pcie_rd_s  pcie_bus_rd_stretch;
   reg 	      pcie_bus_rd_stretcher;

   always@(posedge sys_in.clk) begin
      if (sys_in.reset) begin
	 bus_pcie_wr_buf  <= 'b0;
	 bus_pcie_req_buf <= 'b0;
      end else begin
	 bus_pcie_wr_buf  <= bus_pcie_wr;
	 bus_pcie_req_buf <= bus_pcie_req;
      end
   end
   
   always@(posedge sys.clk) begin
      if (sys.reset) begin
	 bus_pcie_wr_q  <= 'b0;
	 bus_pcie_req_q <= 'b0;
      end else begin
	 bus_pcie_wr_q <= bus_pcie_wr_buf;
	 if (bus_pcie_wr_q.vld == 'b1) begin
	    bus_pcie_wr_q.vld <= 1'b0;
	 end
	 bus_pcie_req_q <= bus_pcie_req_buf;
	 if (bus_pcie_req_q.vld == 'b1) begin
	    bus_pcie_req_q.vld <= 1'b0;
	 end
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk)

   always@(posedge sys.clk) begin
      if (sys.reset) begin
	 pcie_bus_rd_stretch <= 'b0;
      end else begin
	 pcie_bus_rd_stretcher <= pcie_bus_rd_stretch.vld; 
	 if (pcie_bus_rd_stretch.vld == 1'b0) begin
	    pcie_bus_rd_stretch <= pcie_bus_rd_q;
	 end else begin
	    if (pcie_bus_rd_stretcher == 1'b1) begin
	      pcie_bus_rd_stretch <= pcie_bus_rd_q;
	    end
	 end
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk)
   
   always@(posedge sys_in.clk) begin
      if (sys_in.reset) begin
	 pcie_bus_rd <= 'b0;
      end else begin
	 pcie_bus_rd <= pcie_bus_rd_stretch;
      end
   end


endmodule  
