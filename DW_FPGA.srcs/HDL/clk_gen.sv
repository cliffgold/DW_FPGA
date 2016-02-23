module clk_gen
  (
   clk_input,
   rst_in,
   sys
   );
   		
`include "params.svh"
`include "structs.svh"

   input  clk_input;
   input  rst_in;
   output sys_s sys;
   
   wire   locked;
   
   reg    reset;
   reg    reset_q;
   
   always@(posedge sys.clk) begin
      if (rst_in | ~locked) begin
	 reset     <= 1'b0;
	 reset_q   <= 1'b0;
	 sys.reset <= 1'b0;
      end else begin
	 reset     <= rst_in | ~locked;
	 reset_q   <= reset;
	 sys.reset <= reset_q;
      end
   end // always@ (posedge clk)
   

   clk_wiz_0 clk_wiz_0_0
     (
      // Clock in ports
      .clk_in1(clk_input_bufg),      // input clk_in1
      .clkfb_in(sys.clk),
      // Clock out ports
      .clk_out1(clk_output),   // output clk_out1
      .clkfb_out(),            // moved feedback here
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
     .I(clk_input),
     .O(clk_input_bufg)
     );

 endmodule
   