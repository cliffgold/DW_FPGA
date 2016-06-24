//Vary temperature only
mem_pattern_0(rnd_mem);

ctrl_word.word0.next 	     = 'b0;
ctrl_word.word0.flips        = 'h3;
ctrl_word.word0.temperature  = 'h0;
ctrl_word.word0.cutoff       = {1'b1,{SUM_W{1'b0}}};
ctrl_word.word1.count        = 256;

ctrl_addr 	       = 0;
ctrl_addr.addr 	       = 0;

for (i=0;i<NRUNS;i++) begin
   ctrl_addr.run      = i;
   ctrl_word.word0.temperature  = i;
   
   pcie_ctrl_write(CTRL_BAR_START,
		   ctrl_addr,
		   ctrl_word,
		   clk_input,
		   bus_pcie_wr);
   
end // for (i=0;i<3;i++)

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

repeat (100 + (256*NRUNS/2)) @(negedge clk_input);

// Check that values are within expected range

for (i=0;i<NRUNS;i++) begin
   maxerr = 24 + 12*i;
   
   if ($isunknown({old_mem_add_0[i],
		   old_mem_add_255[i],
		   old_mem_add_256[i],
		   old_mem_add_511[i]
		   })) begin
       $error("***** :( TEST FAILED :( *****");
       $display("Unknows on the bus.  Refer to waveform.");
   end
   
   if (old_mem_add_0[i] > maxerr) begin
      $error("***** :( TEST FAILED :( *****");
      $display("Mem 0 on run %0d is %0d should be less than %0d", 
	       i,old_mem_add_0[i],maxerr);
      bad_fail = bad_fail + 1;
   end
   
   if (old_mem_add_255[i] < (1023 - maxerr)) begin
      $error("***** :( TEST FAILED :( *****");
      $display("Mem 255 on run %0d is %0d should be more than %0d", 
	       i,old_mem_add_255[i],maxerr);
      bad_fail = bad_fail + 1;
   end
   
   if ((old_mem_add_256[i] > maxerr) && 
       (old_mem_add_256[i] < (1023 - maxerr))) begin
      $error("***** :( TEST FAILED :( *****");
      $display("Mem 256 on run %0d is %0d should be less than %0d or more than %0d", 
	       i,old_mem_add_256[i],maxerr,1023-maxerr);
      bad_fail = bad_fail + 1;
   end
   
   if ((old_mem_add_511[i] > (512+maxerr)) || 
       (old_mem_add_511[i] < (512 - maxerr))) begin
      $error("***** :( TEST FAILED :( *****");
      $display("Mem 511 on run %0d is %0d should be between 480 and 544", 
	     i,old_mem_add_511[i],512-maxerr,512+maxerr);
      bad_fail = bad_fail + 1;
   end
end // for (i=0;i<NRUNS;i++)

if (bad_fail == 'b0) begin
   $display("*****  :) test_ctrl_temperature PASSED :) *****");
end


 
