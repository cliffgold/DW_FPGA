// This is included, so does not need to be in module.

`include "poke_cmem.svh"

task automatic axi_write
  (
   input reg [7:0]  bar,
   input reg [31:0] addr,
   input reg [31:0] data [0:1023],
   input reg [9:0]  len, //units are DWs

   input reg [15:0] reqid,
		    ref [7:0] tag,
   
   ref reg 	    sys_clk,
   
   input axi_rx_in_s  axi_rx_in,
   ref   axi_rx_out_s axi_rx_out
   
   );
   
   begin
      integer i;
      pcie_hdr_s axi_hdr;

      @(negedge sys_clk);
      axi_hdr         = 'b0;
      
      axi_hdr.w0.wdat = 1'b1;
      axi_hdr.w0.dw4  = 1'b0;
      axi_hdr.w0.typ  = TYPE_MEM;
      axi_hdr.w0.len  = len;
      
      axi_hdr.w1.reqid    = reqid;
      axi_hdr.w1.tag      = tag;
      axi_hdr.w1.last_be  = 4'hf;
      axi_hdr.w1.first_be = 4'hf;
            
      axi_rx_out.tdata     = axi_hdr;
      axi_rx_out.tkeep     = 'hff;
      axi_rx_out.tuser.bar = bar;
      axi_rx_out.tlast     = 1'b0;
      axi_rx_out.tvalid    = 1'b1;
      
      while (axi_rx_in.tready == 1'b0) begin
	 @(negedge sys_clk);
      end
      @(negedge sys_clk);

      axi_rx_out.tdata[31:0]  = addr;
      axi_rx_out.tdata[63:32] = data[0];
      axi_rx_out.tkeep        = 'hff;
      if (len == 1) begin
	 axi_rx_out.tlast = 1;
      end else begin
	 axi_rx_out.tlast = 0;
      end
      axi_rx_out.tvalid       = 1'b1;
      while (axi_rx_in.tready == 1'b0) begin
	 @(negedge sys_clk);
      end
      @(negedge sys_clk);

      i = 1;
      while (i != len) begin
	 if ((len - i) == 'b1) begin
	    axi_rx_out.tdata[31:0]  = data[i];
	    i=i+1;
	    axi_rx_out.tdata[63:32] = 32'b0;
	    axi_rx_out.tkeep        = 'h0f;
	 end else begin
	    axi_rx_out.tdata[31:0]  = data[i];
	    i=i+1;
	    axi_rx_out.tdata[63:32] = data[i];
	    i=i+1;
	    axi_rx_out.tkeep        = 'hff;
	    if (len == i) begin
	       axi_rx_out.tlast        = 1'b1;
	    end else begin
	       axi_rx_out.tlast        = 1'b0;
	    end
	 end
	 axi_rx_out.tvalid    = 1'b1;
	 while (axi_rx_in.tready == 1'b0) begin
	    @(negedge sys_clk);
	 end
	 @(negedge sys_clk);
      end // while (i != len)

      axi_rx_out.tvalid = 1'b0;
      tag = tag+1;
      @(negedge sys_clk);
   end
endtask // while

// task automatic pcie_read
//   (
//    input  reg [31:0] block_offset,
//    input  reg [31:0] addr,
//    output reg [63:0] data,
//    ref    reg 	     sys_clk,
//    ref pcie_req_s    bus_pcie_req,
//    ref pcie_rd_s     pcie_bus_rd
//    );
//    
//    begin : bus_pcie_read
//       @(negedge sys_clk);
//       bus_pcie_req.tag  = bus_pcie_req.tag + 1;
//       bus_pcie_req.addr = block_offset + addr;
//       bus_pcie_req.vld  = 1'b1;
//       
//       @(negedge sys_clk);
//       bus_pcie_req.vld  = 1'b0;
//       while (pcie_bus_rd.vld == 'b0) begin
// 	 @(negedge sys_clk);
//       end
//       data = pcie_bus_rd.data; 
//    end // block: bus_pcie_read
// endtask // while
// 


task automatic mem_pattern_0 (output [NCMEMS-1:0] mem [3:0]);
   integer i;
   reg [11:0] val;
   mem[0] = 0;
   mem[1] = 255;
   mem[2] = 256;
   mem[3] = 511;
   
   begin : mem_patt_0
      for (i=0;i<1024;i=i+1) begin
	 // $write(" %5d, ",i);
	 val = -2048 + (i*4);
	 // $write(" %4x, ",val);
	 sim_top.top_0.coef_0.\cmem[0].coef_mem_0 .inst.\native_mem_module.blk_mem_gen_v8_3_2_inst .memory[i]   = val;
	 val = 2047 - (i*4);
	 // $write(" %4x, ",val);
	 sim_top.top_0.coef_0.\cmem[255].coef_mem_0 .inst.\native_mem_module.blk_mem_gen_v8_3_2_inst .memory[i] = val;
	 
	 if (i < 512) begin
	    val = -2048 + (i*8);
	    // $write(" %4x, ",val);
	    sim_top.top_0.coef_0.\cmem[256].coef_mem_0 .inst.\native_mem_module.blk_mem_gen_v8_3_2_inst .memory[i] = val;
	    val = 2047 - (i*8);
	    // $display(" %4x, ",val);
	    sim_top.top_0.coef_0.\cmem[511].coef_mem_0 .inst.\native_mem_module.blk_mem_gen_v8_3_2_inst .memory[i] = val;
	 end else begin
	    val = 4096  + 2047 - (i*8);
	    // $write(" %4x, ",val);
	    sim_top.top_0.coef_0.\cmem[256].coef_mem_0 .inst.\native_mem_module.blk_mem_gen_v8_3_2_inst .memory[i] = val;
	    val = -4096 - 2048 + (i*8);
	    // $display(" %4x, ",val);
	    sim_top.top_0.coef_0.\cmem[511].coef_mem_0 .inst.\native_mem_module.blk_mem_gen_v8_3_2_inst .memory[i] = val;
	 end
      end // for (i=0;i<1024;i=i+1)
   end // block: mem_patt_0
endtask // mem_pattern_0






   
