module clk_gen
  (
   clk_input,
   rst_in,

   sys,
   sys_in
   );
   		
`include "params.svh"
`include "structs.svh"

   input  clk_input;
   input  rst_in;

   output sys_s sys;
   output sys_s sys_in;
   
   wire   locked;
   wire   clkin_out;

   reg    reset;
   reg    reset_q;
   reg    reset_in;
   reg    reset_in_q;
   
   always@(posedge sys.clk) begin
      if (reset_in_q) begin
	 reset     <= 1'b1;
	 reset_q   <= 1'b1;
	 sys.reset <= 1'b1;
      end else begin
	 reset     <= 1'b0;
	 reset_q   <= reset;
	 sys.reset <= reset_q;
      end
   end // always@ (posedge clk)
   
   clk_wiz_0 clk_wiz_0_0
     (
      // Clock in ports
      .clk_in1(clk_input),      // input clk_in1
      .clkfb_in(sys_in.clk),
      // Clock out ports
      .clk_out1(clk_output),   // output clk_out1
      .clk_out2(clkin_out),
      .clkfb_out(),
      // Status and control signals
      .reset(rst_in),        // input reset
      .locked(locked)    // output locked
      );    

   BUFG clkout_bufg_0
     (
      .I(clk_output),
      .O(sys.clk)
      );
   
   BUFG clkin_bufg_0
     (
      .I(clkin_out),
      .O(sys_in.clk)
      );

   always@(posedge sys_in.clk) begin
      if (rst_in | ~locked) begin
	 reset_in     <= 1'b1;
	 reset_in_q   <= 1'b1;
	 sys_in.reset <= 1'b1;
      end else begin
	 reset_in     <= 1'b0;
	 reset_in_q   <= reset_in;
	 sys_in.reset <= reset_in_q;
      end
   end // always@ (posedge clk)
   
   
endmodule
   
