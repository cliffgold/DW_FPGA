//Top level of sim
//Includes HDL Design, clocks, and tests as listed in test.list
module sim_top();

`include "params.svh"
`include "structs.svh"
`include "sim_structs.svh"   
`include "sim_tasks.svh"

   reg clk_input;
   reg rst_in;
   reg ready;
   
   pcie_wr_s    bus_pcie_wr;
   pcie_req_s   bus_pcie_req;

   pcie_rd_s   pcie_bus_rd;

   pcie_cmem_s pcie_cmem;
   
   reg [63:0] test_data_rd;
   reg [63:0] test_data_wr;
   
   reg [31:0]  bad_fail;
        
   top top_0
     (
      .clk_input(clk_input),
      .rst_in(rst_in),
      .bus_pcie_wr_data(bus_pcie_wr.data),
      .bus_pcie_wr_vld(bus_pcie_wr.vld), 
      .bus_pcie_wr_addr(bus_pcie_wr.addr),
                       
      .bus_pcie_req_tag(bus_pcie_req.tag),
      .bus_pcie_req_vld(bus_pcie_req.vld),
      .bus_pcie_req_addr(bus_pcie_req.addr),

      .pcie_bus_rd_data(pcie_bus_rd.data),
      .pcie_bus_rd_vld(pcie_bus_rd.vld),
      .pcie_bus_rd_tag(pcie_bus_rd.tag) 
      );
   

   initial begin
      rst_in       = 1'b1;
      clk_input    = 1'b0;
      bus_pcie_wr  = 'b0;
      bus_pcie_req = 'b0;
      pcie_cmem    = 'b0;
      ready        = 1'b0;
      
      #10;
      
      repeat(50) begin
	 #5
	   clk_input = ~clk_input;
      end

      rst_in = 0;

      while (top_0.clk_gen_0.locked == 1'b0) begin
	 #5
	   clk_input = ~clk_input;
      end
      
      repeat(50) begin
	 #5
	   clk_input = ~clk_input;
      end

      ready = 1;
      
      forever begin
	 #5
	   clk_input = ~clk_input;
      end
   end // initial begin
   
   initial begin
    bad_fail = 0;
      @(posedge ready);
      @(negedge clk_input);
      @(negedge clk_input);
`include "testlist.svh"
      @(negedge clk_input);
      @(negedge clk_input);
      $finish();
   end
   
endmodule // sim_top

