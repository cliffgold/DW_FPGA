//Check sum circuit
//Fill each memory with a different constant pattern
//Then, no matter what the XY's, sum should be the same

test_sum = 0;

for (i=0;i<NCMEMS;i++) begin
   test_subtotal = $random();
   test_sum      = test_sum + test_subtotal;
   //$display("subtotal %0d sum %0d",test_subtotal,test_sum);
   
   for (j=0;j<NCMEM_ADDRS;j++) begin
      coef_mem[i][j] = test_subtotal;
   end
end

poke_cmem(coef_mem);

ctrl_word.next 	       = 'b0;
ctrl_word.flips        = 'h0;
ctrl_word.temperature  = 'h0;
ctrl_word.count        = 10;

ctrl_addr 	       = 0;

for (i=0;i<NRUNS;i++) begin
   ctrl_addr.addr = i;
   
   pcie_write(CTRL_BAR_START,
	      ctrl_addr,
	      ctrl_word,
	      clk_input,
	      bus_pcie_wr);
end

repeat (NRUNS) @(negedge clk_input);

ctrl_cmd      = 'b0;
ctrl_cmd.init = 'b1;

ctrl_addr        = 'b0;
ctrl_addr.is_cmd = 'b1;

pcie_write(CTRL_BAR_START,
	   ctrl_addr,
	   ctrl_cmd,
	   clk_input,
	   bus_pcie_wr);

repeat (NRUNS) @(negedge clk_input);

ctrl_cmd       = 'b0;
ctrl_cmd.start =  {NRUNS{1'b1}};

ctrl_addr        = 'b0;
ctrl_addr.is_cmd = 'b1;

pcie_write(CTRL_BAR_START,
	   ctrl_addr,
	   ctrl_cmd,
	   clk_input,
	   bus_pcie_wr);

repeat (100 + (10*NRUNS/2)) @(negedge clk_input);

// Check that values are === sum
for (i=0;i<NRUNS;i++) begin

   pcie_read (PICK_BAR_START,
	      i,
	      test_data_rd,
	      clk_input,
	      bus_pcie_req,
	      pcie_bus_rd);

   if ($signed(test_data_rd) !== test_sum) begin
      $error("***** :( TEST FAILED :( *****");
      $display("Run %0d, sum was %0d, expected %0d",
	       i,$signed(test_data_rd),test_sum);
	 
      bad_fail = bad_fail + 1;
   end
end
     
if (bad_fail == 0) begin
   $display("*****  :) test_sum PASSED :) *****");
end
   

 
