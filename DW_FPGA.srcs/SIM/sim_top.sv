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
        
   top top_0
     (
      .clk_input(clk_input),
      .rst_in(rst_in),
      .bus_pcie_wr(bus_pcie_wr),
      .bus_pcie_req(bus_pcie_req),

      .pcie_bus_rd(pcie_bus_rd)
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
   
`include "testlist.svh"
endmodule // sim_top

