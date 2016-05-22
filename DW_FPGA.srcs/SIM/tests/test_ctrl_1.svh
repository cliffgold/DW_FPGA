//Program controller, start running
mem_pattern_0(rnd_mem);

ctrl_word.ctrl1.next 	     = 'b1;
ctrl_word.ctrl1.flips 	     = 'h1;
ctrl_word.ctrl1.temperature  = 'h2;
ctrl_word.ctrl0.count 	     = 32;

rnd_run[0] = 0;
rnd_run[1] = MAX_RUN_BITS/2;
rnd_run[2] = MAX_RUN_BITS;
rnd_run[3] = MAX_RUN_BITS/3;

ctrl_addr = 0;

for (i=0;i<4;i++) begin
   ctrl_addr.run   = rnd_run[i];
   ctrl_addr.ctrl1 = 1'b0;
   
   pcie_write(CTRL_BAR_START,
	      ctrl_addr,
	      ctrl_word.ctrl0,
	      clk_input,
	      bus_pcie_wr);

   ctrl_addr.ctrl1 = 'b1;
   
   pcie_write(CTRL_BAR_START,
	      ctrl_addr,
	      ctrl_word.ctrl1,
	      clk_input,
	      bus_pcie_wr);
end // for (i=0;i<3;i++)

ctrl_word.ctrl1.next 	     = 'b0;
ctrl_word.ctrl1.flips 	     = 'h3;
ctrl_word.ctrl1.temperature  = 'h2;
ctrl_word.ctrl0.count 	     = 128;

ctrl_addr      = 0;
ctrl_addr.addr = 1;

for (i=0;i<4;i++) begin
   ctrl_addr.run   = rnd_run[i];
   ctrl_addr.ctrl1 = 1'b0;
   
   pcie_write(CTRL_BAR_START,
	      ctrl_addr,
	      ctrl_word.ctrl0,
	      clk_input,
	      bus_pcie_wr);

   ctrl_addr.ctrl1 = 'b1;
   
   pcie_write(CTRL_BAR_START,
	      ctrl_addr,
	      ctrl_word.ctrl1,
	      clk_input,
	      bus_pcie_wr);
end // for (i=0;i<3;i++)

repeat (MAX_RUN_BITS+1) @(negedge clk_input);

ctrl_cmd      = 'b0;
ctrl_cmd.init = 'b1;

ctrl_addr        = 'b0;
ctrl_addr.is_cmd = 'b1;

pcie_write(CTRL_BAR_START,
	   ctrl_addr,
	   ctrl_cmd,
	   clk_input,
	   bus_pcie_wr);

repeat (MAX_RUN_BITS+1) @(negedge clk_input);

ctrl_cmd       = 'b0;
ctrl_cmd.start =  'b1 | 
		 ('b1 << (MAX_RUN_BITS/3)) | 
		 ('b1 << (MAX_RUN_BITS/2)) | 
		 ('b1 << MAX_RUN_BITS);

ctrl_addr        = 'b0;
ctrl_addr.is_cmd = 'b1;

pcie_write(CTRL_BAR_START,
	   ctrl_addr,
	   ctrl_cmd,
	   clk_input,
	   bus_pcie_wr);

repeat (100 + 160*(MAX_RUN_BITS+1)/2) @(negedge clk_input);

// Check that values are within expected range

for (i=0;i<4;i++) begin
   if (old_mem_add_0[rnd_run[i]] > 32) begin
      $error("***** :( TEST FAILED :( *****\n Mem 0 is too large on run %0d is %0d should be less than 32", 
	     rnd_run[i],old_mem_add_0[rnd_run[i]]);
      bad_fail = bad_fail + 1;
   end
   if (old_mem_add_255[rnd_run[i]] < (1023 - 32)) begin
      $error("***** :( TEST FAILED :( *****\n Mem 255 is too small on run %0d is %0d should be more than (1023-32)", 
	     rnd_run[i],old_mem_add_0[rnd_run[i]]);
      bad_fail = bad_fail + 1;
   end
   if ((old_mem_add_256[rnd_run[i]] > 32) && (old_mem_add_256[rnd_run[i]] < (1023 - 32))) begin
       $error("***** :( TEST FAILED :( *****\n Mem 0 is too middling on run %0d is %0d should be less than 32 or more than 991", 
	      rnd_run[i],old_mem_add_0[rnd_run[i]]);
      bad_fail = bad_fail + 1;
   end
   if ((old_mem_add_511[rnd_run[i]] > (512+32)) || (old_mem_add_511[rnd_run[i]] < (512 - 32))) begin
      $error("***** :( TEST FAILED :( *****\n Mem 0 is not near the middle on run %0d is %0d should be between 480 and 544", 
	     rnd_run[i],old_mem_add_0[rnd_run[i]]);
      bad_fail = bad_fail + 1;
   end
end // for (i=0;i<4;i++)


// Check a couple of random memory reads vs. peek

for (i=0;i<8;i++) begin
   randnum = $random();
   j = randnum[MAX_QWORD+2:MAX_QWORD+1]; //used for run number
   if (randnum[MAX_QWORD] == 1'b0) begin
      test_data_ex = old_x[rnd_run[j]] [randnum[MAX_QWORD-1:0]*64 +:64];
   end else begin
      test_data_ex = old_y[rnd_run[j]] [randnum[MAX_QWORD-1:0]*64 +:64];
   end

   rnd_addr.run = rnd_run[j];
   rnd_addr.addr = randnum[MAX_QWORD:0];
      
   pcie_read(RND_BAR_START,
	     rnd_addr,
	     test_data_rd,
	     clk_input,
	     bus_pcie_req,
	     pcie_bus_rd);

      if (test_data_rd !== test_data_ex) begin
	 $error("***** :( TEST FAILED :( *****\n Read xy does not match expected for %0x:%0x run %0d expected %0x got %0x",
		rnd_addr.addr*64+63,
		rnd_addr.addr*64,
		rnd_addr.run,
		test_data_ex,test_data_rd);
	 bad_fail = bad_fail + 1;
      end
end // for (i=0;i<3;i++)

if (bad_fail == 'b0) begin
   $display("*****  :) test_ctrl_1 PASSED :) *****");
end


 
