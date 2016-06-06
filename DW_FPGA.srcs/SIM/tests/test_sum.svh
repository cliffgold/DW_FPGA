//Check sum circuit
//Fill each memory with a different constant pattern
//Then, no matter what the XY's, sum should be the same


ctrl_word.next 	       = 'b0;
ctrl_word.flips        = 'h0;
ctrl_word.temperature  = 'h0;
ctrl_word.count        = 10;

ctrl_addr 	       = 0;

for (i=0;i<NRUNS;i++) begin
   ctrl_addr.run= i;
   
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

for (k=0;k<4;k++) begin
   test_ex_sum = 0;
   for (i=0;i<NCMEMS;i++) begin
      case (k)
	0: test_subtotal = $random();
	1: test_subtotal = -2048;
	2: test_subtotal = 2047;
	3: test_subtotal = $random();
      endcase
      test_ex_sum      = test_ex_sum + test_subtotal;
   //$display("subtotal %0d sum %0d",test_subtotal,test_ex_sum);
   
      for (j=0;j<NCMEM_ADDRS;j++) begin
	 coef_mem[i][j] = test_subtotal;
      end
   end

   $display("Pattern %0d,total %0d",k,test_ex_sum);
   
   poke_cmem(coef_mem);
   
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
      
      test_sum = test_data_rd[SUM_W:0];
            
      if (test_sum !== test_ex_sum) begin
	 $error("***** :( TEST FAILED :( *****");
	 $display("Pattern %0d, Run %0d, sum was %0d, expected %0d",
		  k,i,$signed(test_data_rd),test_ex_sum);
	 
	 bad_fail = bad_fail + 1;
      end
   end // for (i=0;i<NRUNS;i++)
end // for (k=0;k<3;k++)
     
if (bad_fail == 0) begin
   $display("*****  :) test_sum PASSED :) *****");
end
   

 
