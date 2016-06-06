//Top level of sim
//Includes HDL Design, clocks, and tests as listed in test.list
`include "timescale.svh"

module sim_top();

`include "params.svh"
`include "structs.svh"
`include "sim_tasks.svh"

   reg clk_input;
   reg rst_in;
   reg ready;
   reg sys_clk;
   
   pcie_wr_s    bus_pcie_wr;
   pcie_req_s   bus_pcie_req;

   pcie_rd_s   pcie_bus_rd;

   coef_addr_s coef_addr;
   
   ctrl_addr_s ctrl_addr;
   ctrl_cmd_s  ctrl_cmd;
   ctrl_word_s ctrl_word;

   pcie_rnd_addr_s            rnd_addr;
   reg [RUN_W:0] 	      rnd_run [0:NRUNS-1];
   reg [X_W:0] 		      test_x [0:NRUNS-1];
   reg [Y_W:0] 		      test_y [0:NRUNS-1];

   reg [NCMEMS-1:0] 	      rnd_mem [3:0];
      
   reg [63:0] 		      test_data_rd;
   reg [63:0] 		      test_data_wr;
   reg [63:0] 		      test_data_ex;
   reg [31:0] 		      test_addr;
   
   reg [31:0] 		      bad_fail;
        
   reg [CMEM_SEL_W:0] 	      test_coef_sel [0:3];
   reg [CMEM_ADDR_W:0] 	      test_coef_addr [0:3];
   reg [CMEM_DATA_W:0] 	      test_coef_data [0:3][0:3];

   reg signed [SUM_W:0]       test_ex_sum;
   reg signed [SUM_W:0]       test_sum;
   reg signed [CMEM_DATA_W:0] test_subtotal;

   reg [CMEM_DATA_W:0] 	      coef_mem [0:NCMEMS-1] [0:NCMEM_ADDRS-1];

   integer 		      i;
   integer 		      j;
   integer 		      k;
   integer 		      randnum;
   integer 		      maxerr;
   

   top 
     #(.IS_SIM(1))
     top_0
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
      ready        = 1'b0;
      
      #CLK_IN_PERIOD;
      
      repeat(50) begin
	 #(CLK_IN_PERIOD/2)
	   clk_input = ~clk_input;
      end

      rst_in = 0;

      assign sys_clk = top_0.clk_gen_0.sys.clk;
      
      while (top_0.clk_gen_0.locked == 1'b0) begin
	 #(CLK_IN_PERIOD/2)
	   clk_input = ~clk_input;
      end
      
      repeat(50) begin
	 #(CLK_IN_PERIOD/2)
	   clk_input = ~clk_input;
      end

      ready = 1;
      
      forever begin
	 #(CLK_IN_PERIOD/2)
	   clk_input = ~clk_input;
      end
   end // initial begin
   
   initial begin
      bad_fail = 0;
      @(posedge ready);
      @(negedge sys_clk);
      @(negedge sys_clk);
`include "testlist.svh"
      @(negedge sys_clk);
      @(negedge sys_clk);
      $finish();
   end
 
// Test Signals
//************************* Old x/y values (previous winners)  ********************   
   
   reg [9:0] old_mem_add_0   [0:NRUNS-1];
   reg [9:0] old_mem_add_255 [0:NRUNS-1];
   reg [9:0] old_mem_add_256 [0:NRUNS-1];
   reg [9:0] old_mem_add_511 [0:NRUNS-1];
   
   reg [X_W:0]     old_x [0:NRUNS-1];
   reg [Y_W:0]     old_y [0:NRUNS-1];

   always@(negedge sys_clk) begin
      {old_y[top_0.rnd_0.run],old_x[top_0.rnd_0.run]} <= 
		             top_0.rnd_0.old_xy_out;
   end
   
   genvar    gi;
   
generate
   for (gi=0;gi<=NRUNS-1;gi++) begin : old_sig
      
      assign old_mem_add_0[gi] = {
		   old_x[gi] [1],
		   old_x[gi] [0],
		   old_y[gi] [65],
		   old_y[gi] [64],
		   old_y[gi] [3],
		   old_y[gi] [3],
		   old_y[gi] [2],
		   old_y[gi] [3],
		   old_y[gi] [1],
		   old_y[gi] [0],
		   1'b0,
		   1'b0
 		   };

      assign old_mem_add_255[gi] = {
		   old_x[gi] [511],
		   old_x[gi] [510],
		   old_y[gi] [575],
		   old_y[gi] [574],
		   old_y[gi] [511],
		   old_y[gi] [510],
		   old_y[gi] [509],
		   old_y[gi] [508],
		   old_y[gi] [447],
		   old_y[gi] [446]
		   };
   
      assign old_mem_add_256[gi] = {
		   old_x[gi] [513],
		   old_x[gi] [512],
		   old_y[gi] [577],
		   old_y[gi] [576],
		   old_y[gi] [515],
		   old_y[gi] [514],
		   old_y[gi] [513],
		   old_y[gi] [512],
		   old_y[gi] [449],
		   old_y[gi] [448]
		   };
   
      assign old_mem_add_511[gi] = {
		   old_x[gi] [1023],
		   old_x[gi] [1022],
		   1'b0,
		   1'b0,
		   old_y[gi] [1023],
		   old_y[gi] [1022],
		   old_y[gi] [1021],
		   old_y[gi] [1020],
		   old_y[gi] [959],
		   old_y[gi] [958]
		   };
   
   end // block: old_sig
   
endgenerate
//    
// // ************************* New x/y values for comparison ********************   
//    reg [9:0] new_mem_add_0   [0:NRUNS-1];
//    reg [9:0] new_mem_add_255 [0:NRUNS-1];
//    reg [9:0] new_mem_add_256 [0:NRUNS-1];
//    reg [9:0] new_mem_add_511 [0:NRUNS-1];
//    
//    reg [X_W:0]     new_x [0:NRUNS-1];
//    reg [Y_W:0]     new_y [0:NRUNS-1];
// 
//    always@(negedge sys_clk) begin
//       {new_y[top_0.rnd_0.run],new_x[top_0.rnd_0.run]} <= 
// 		             top_0.rnd_0.new_xy[NRUNS-1];
//    end
//    
// generate
//    for (gi=0;gi<=NRUNS-1;gi++) begin : new_sig
//       
//       assign new_mem_add_0[gi] = {
// 		   1'b0,
// 		   1'b0,
// 		   new_y[gi] [0],
// 		   new_y[gi] [1],
// 		   new_y[gi] [2],
// 		   new_y[gi] [3],
// 		   new_y[gi] [64],
// 		   new_y[gi] [65],
// 		   new_x[gi] [0],
// 		   new_x[gi] [1]
// 		   };
// 			    
//    assign new_mem_add_255[gi] = {
// 		   new_y[gi] [446],
// 		   new_y[gi] [447],
// 		   new_y[gi] [508],
// 		   new_y[gi] [509],
// 		   new_y[gi] [510],
// 		   new_y[gi] [511],
// 		   new_y[gi] [574],
// 		   new_y[gi] [575],
// 		   new_x[gi] [510],
// 		   new_x[gi] [511]
// 		   };
//    
//    assign new_mem_add_256[gi] = {
// 		   new_y[gi] [448],
// 		   new_y[gi] [449],
// 		   new_y[gi] [512],
// 		   new_y[gi] [513],
// 		   new_y[gi] [514],
// 		   new_y[gi] [515],
// 		   new_y[gi] [576],
// 		   new_y[gi] [577],
// 		   new_x[gi] [512],
// 		   new_x[gi] [513]
// 		   };
//    
//    assign new_mem_add_511[gi] = {
// 		   new_y[gi] [958],
// 		   new_y[gi] [959],
// 		   new_y[gi] [1020],
// 		   new_y[gi] [1021],
// 		   new_y[gi] [1022],
// 		   new_y[gi] [1023],
// 		   1'b0,
// 		   1'b0,
// 		   new_x[gi] [1022],
// 		   new_x[gi] [1023]
// 		   };
//    end // block: new_sig
// endgenerate
//    

endmodule // sim_top

