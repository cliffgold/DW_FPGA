// This is included, so does not need to be in module.

`include "poke_cmem.svh"

task automatic axi_write
  (
   input [7:0]  bar,
   input [31:2] addr,
   input [31:0] data [0:1023],
   input [9:0]  len, //units are DWs
   input        wdat,

   input [15:0] reqid,
		    ref [7:0] tag,
   
   ref reg 	    sys_clk,
   
   input 	    axi_rx_in_s axi_rx_in,
   ref              axi_rx_out_s axi_rx_out
   
   );
   
   begin : axi_write
      integer i;
      pcie_hdr_s pcie_hdr;
      
      @(negedge sys_clk);
      pcie_hdr         = 'b0;
      
      pcie_hdr.w0.wdat = wdat;
      pcie_hdr.w0.dw4  = 1'b0;
      pcie_hdr.w0.typ  = TYPE_MEM;
      pcie_hdr.w0.len  = len;
      
      pcie_hdr.w1.reqid    = reqid;
      pcie_hdr.w1.tag      = tag;
      pcie_hdr.w1.last_be  = 4'hf;
      pcie_hdr.w1.first_be = 4'hf;
            
      axi_rx_out.tdata     = pcie_hdr;
      axi_rx_out.tkeep     = 'hff;
      axi_rx_out.tuser.bar = bar;
      axi_rx_out.tlast     = 1'b0;
      axi_rx_out.tvalid    = 1'b1;
      
      while (axi_rx_in.tready == 1'b0) begin
	 @(negedge sys_clk);
      end
      @(negedge sys_clk);

      if ((wdat == 1) && (len > 0)) begin
	 axi_rx_out.tdata[1:0]   = 'b0;
	 axi_rx_out.tdata[31:2]  = addr;
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
      end // if ((wdat == 1) && (len > 0))
      else begin //Is a read request
	 axi_rx_out.tdata[1:0]   = 'b0;
	 axi_rx_out.tdata[31:2]  = addr;
	 axi_rx_out.tdata[63:32] = 32'b0;
	 axi_rx_out.tkeep        = 'h0f;
	 axi_rx_out.tlast        = 1;
	 axi_rx_out.tvalid       = 1'b1;
	 while (axi_rx_in.tready == 1'b0) begin
	    @(negedge sys_clk);
	 end
	 @(negedge sys_clk);
      end // else: !if((wdat == 1) && (len > 0))
      
      axi_rx_out.tvalid = 1'b0;
      tag = tag+1;
      @(negedge sys_clk);
   end // block: axi_write
endtask // while

task automatic axi_read
  (
   input [7:0] 	 bar,
   input [31:2]  addr,
   input [9:0] 	 len, //units are DWs
   output [31:0] data [0:1023],

   input [15:0]  reqid,
   input pcie_cpl_id_s cpl_id,
   ref    [7:0] tag,
   
   ref reg 	 sys_clk,
   
   ref  	 axi_rx_in_s axi_rx_in,
   ref           axi_rx_out_s axi_rx_out,
   
   ref  	 axi_tx_in_s axi_tx_in,
   ref           axi_tx_out_s axi_tx_out
   
   );
   
   begin : axi_read
      integer    i;
      pcie_cpl_qw0_s pcie_cpl_qw0;
      pcie_cpl_dw2_s pcie_cpl_dw2;
      
//send read req
  
      axi_write(.bar(bar),
		.addr(addr),
		.data(axi_data),
		.len(len),
		.wdat(0),

		.reqid(reqid),
		.tag(tag),
		.sys_clk(sys_clk),
		.axi_rx_in(axi_rx_in),
		.axi_rx_out(axi_rx_out)
		);

//gather data
      axi_tx_out.tready = 1'b1;
      
      while (axi_tx_in.tvalid == 1'b0) begin
	 @(negedge sys_clk);
      end
      pcie_cpl_qw0 = axi_tx_in.tdata[63:0];

      if (
	  (pcie_cpl_qw0.w0.wdat !== 1)         ||
	  (pcie_cpl_qw0.w0.dw4  !== 1'b0)      ||
	  (pcie_cpl_qw0.w0.typ  !== TYPE_CPL)  ||
	  (pcie_cpl_qw0.w0.len  !== len)       ||
	  
	  (pcie_cpl_qw0.w1.id   !== cpl_id)    ||
	  (pcie_cpl_qw0.w1.stat !== OK)        ||
	  (pcie_cpl_qw0.w1.cnt  !== len)
	  ) begin

	 $error("Header QW0 error on read");
	 $display("wdat %0x %0x dw4 %0x %0x typ %0x %0x len %0x %0x",
		  pcie_cpl_qw0.w0.wdat,1'h1,
		  pcie_cpl_qw0.w0.dw4,1'b0,
		  pcie_cpl_qw0.w0.typ,TYPE_CPL,
		  pcie_cpl_qw0.w0.len,len
		  );
	 $display("cpl_id %0x %0x stat %0x %0x cnt %0x %0x",
		  pcie_cpl_qw0.w1.id,cpl_id,  
		  pcie_cpl_qw0.w1.stat,OK,
		  pcie_cpl_qw0.w1.cnt,len
		  );
	 		  
	 repeat(10) @(negedge sys_clk);
	 $finish;
      end // if (...
      @(negedge sys_clk);

      while (axi_tx_in.tvalid == 1'b0) begin
	 @(negedge sys_clk);
      end
      pcie_cpl_dw2 = axi_tx_in.tdata[31:0];
      if (
 	  (pcie_cpl_dw2.tag      !== ((tag - 1)&(8'hff)))  ||
	  (pcie_cpl_dw2.reqid    !== reqid)    ||
	  (pcie_cpl_dw2.low_addr !== addr[6:2])
	  ) begin
	 
	 $error("Header DW2 error on read");
	 $display("tag %0x %0x reqid %0x %0x low_addr %0x %0x",
		  pcie_cpl_dw2.tag,(tag - 1)&(8'hff),     
		  pcie_cpl_dw2.reqid,reqid,   
		  pcie_cpl_dw2.low_addr,addr[6:2]
		  );
	 
	 repeat(10) @(negedge sys_clk);
	 $finish;
      end
      
      data[0] = axi_tx_in.tdata[63:32];
      @(negedge sys_clk);
      
      for (i=1;i<len;i=i+2) begin
	 while (axi_tx_in.tvalid == 1'b0) begin
	    @(negedge sys_clk);
	 end
	 data[i] = axi_tx_in.tdata[31:0];
	 data[i+1][31:0] = axi_tx_in.tdata[63:32];
	 @(negedge sys_clk);
      end
      
      axi_tx_out.tready = 1'b0;
      @(negedge sys_clk);
   end // block: axi_read
endtask

task automatic kick_off
  (
   input [NRUNS-1:0] start,
   
   input [15:0] reqid,
		    ref [7:0] tag,
   
   ref reg 	    sys_clk,
   
   input 	    axi_rx_in_s axi_rx_in,
   ref              axi_rx_out_s axi_rx_out
   
   );

   begin : kick_off
      ctrl_addr_s ctrl_addr;
      ctrl_cmd_s  ctrl_cmd;

      reg [31:0] axi_data [0:1023];

      ctrl_cmd      = 'b0;
      ctrl_cmd.init = 'b1;

      axi_data[0]      = ctrl_cmd[31:0];
      axi_data[1]      = ctrl_cmd[CTRL_CMD_S_W:32];
      
      ctrl_addr        = 'b0;
      ctrl_addr.is_cmd = 'b1;
      
      axi_write(.bar(FREAK_BAR),
		.addr(ctrl_addr),
		.data(axi_data),
		.len(2),
		.wdat(1),
		
		.reqid(reqid),
		.tag(tag),
		.sys_clk(sys_clk),
		.axi_rx_in(axi_rx_in),
		.axi_rx_out(axi_rx_out)
		);

      ctrl_cmd       = 'b0;
      ctrl_cmd.start =  start;

      axi_data[0]      = ctrl_cmd[31:0];
      axi_data[1]      = ctrl_cmd[CTRL_CMD_S_W:32];
      
      ctrl_addr        = 'b0;
      ctrl_addr.is_cmd = 'b1;
      
      axi_write(.bar(FREAK_BAR),
		.addr(ctrl_addr),
		.data(axi_data),
		.len(2),
		.wdat(1),
		
		.reqid(reqid),
		.tag(tag),
		.sys_clk(sys_clk),
		.axi_rx_in(axi_rx_in),
		.axi_rx_out(axi_rx_out)
		);
   end // block: kick_off
endtask // kick_off

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






   
