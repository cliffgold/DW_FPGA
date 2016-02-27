//This file is just included in sim_top, so does not need to be a module

initial begin
   @(posedge ready);
   @(negedge clk_input);
   @(negedge clk_input);
`include "tests/test_coef_wrrd_0.svh"
   @(negedge clk_input);
   @(negedge clk_input);
   $finish();
   
end
   
