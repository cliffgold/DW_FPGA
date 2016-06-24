//Normal Run
mem_pattern_0(rnd_mem);

ctrl_word.word0.next 	     = 'b1;
ctrl_word.word0.flips        = 'h1;
ctrl_word.word0.temperature  = 'h0;
ctrl_word.word0.cutoff       = {1'b1,{SUM_W{1'b0}}};
ctrl_word.word1.count        = 32;

rnd_run[0] 	       = 0;
rnd_run[1] 	       = (NRUNS-1)/2;
rnd_run[2] 	       = NRUNS-1;
rnd_run[3] 	       = (NRUNS-1)/3;

ctrl_addr 	       = 0;

for (i=0;i<4;i++) begin
   ctrl_addr.run      = rnd_run[i];
   
   pcie_ctrl_write(CTRL_BAR_START,
		   ctrl_addr,
		   ctrl_word,
		   clk_input,
		   bus_pcie_wr);
   
end

ctrl_word.word0.next 	     = 'b1;
ctrl_word.word0.flips        = 'h3;
ctrl_word.word0.temperature  = 'h0;
ctrl_word.word0.cutoff       = {1'b1,{SUM_W{1'b0}}};
ctrl_word.word1.count        = 128;

ctrl_addr 	       = 0;
ctrl_addr.addr 	       = 1;

for (i=0;i<4;i++) begin
   ctrl_addr.run      = rnd_run[i];
   
   pcie_ctrl_write(CTRL_BAR_START,
		   ctrl_addr,
		   ctrl_word,
		   clk_input,
		   bus_pcie_wr);
   
end // for (i=0;i<3;i++)

repeat (NRUNS) @(negedge clk_input);

ctrl_word.word0.next 	     = 'b0;
ctrl_word.word0.flips        = 'h5;
ctrl_word.word0.temperature  = 'h0;
ctrl_word.word0.cutoff       = {1'b1,{SUM_W{1'b0}}};
ctrl_word.word1.count        = 128;

ctrl_addr 	       = 0;
ctrl_addr.addr 	       = 2;

for (i=0;i<4;i++) begin
   ctrl_addr.run      = rnd_run[i];
   
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
ctrl_cmd.start =  'b1 | 
		 ('b1 << ((NRUNS-1)/3)) | 
		 ('b1 << ((NRUNS-1)/2)) | 
		 ('b1 << (NRUNS-1));

ctrl_addr        = 'b0;
ctrl_addr.is_cmd = 'b1;

pcie_write(CTRL_BAR_START,
	   ctrl_addr,
	   ctrl_cmd,
	   clk_input,
	   bus_pcie_wr);

repeat (100 + ((32+128+128)*NRUNS/2)) @(negedge clk_input);

// Check that values are within expected range
maxerr = 48;

for (i=0;i<4;i++) begin
   if ($isunknown({old_mem_add_0[rnd_run[i]],
		   old_mem_add_255[rnd_run[i]],
		   old_mem_add_256[rnd_run[i]],
		   old_mem_add_511[rnd_run[i]]
		   })) begin
       $error("***** :( TEST FAILED :( *****");
       $display("Unknows on the bus.  Refer to waveform.");
   end
   
   if (old_mem_add_0[rnd_run[i]] > maxerr) begin
      $error("***** :( TEST FAILED :( *****");
      $display("Mem 0 on run %0d is %0d should be less than %0d", 
	       rnd_run[i],old_mem_add_0[rnd_run[i]],maxerr);
      bad_fail = bad_fail + 1;
   end
   
   if (old_mem_add_255[rnd_run[i]] < (1023 - maxerr)) begin
      $error("***** :( TEST FAILED :( *****");
      $display("Mem 255 on run %0d is %0d should be more than %0d", 
	       rnd_run[i],old_mem_add_255[rnd_run[i]],maxerr);
      bad_fail = bad_fail + 1;
   end
   
   if ((old_mem_add_256[rnd_run[i]] > maxerr) && 
       (old_mem_add_256[rnd_run[i]] < (1023 - maxerr))) begin
      $error("***** :( TEST FAILED :( *****");
      $display("Mem 256 on run %0d is %0d should be less than %0d or more than %0d", 
	       rnd_run[i],old_mem_add_256[rnd_run[i]],maxerr,1023-maxerr);
      bad_fail = bad_fail + 1;
   end
   
   if ((old_mem_add_511[rnd_run[i]] > (512+maxerr)) || 
       (old_mem_add_511[rnd_run[i]] < (512 - maxerr))) begin
      $error("***** :( TEST FAILED :( *****");
      $display("Mem 511 on run %0d is %0d should be between 480 and 544", 
	     rnd_run[i],old_mem_add_511[rnd_run[i]],512-maxerr,512+maxerr);
      bad_fail = bad_fail + 1;
   end
end // for (i=0;i<4;i++)


// Check a couple of random memory reads vs. peek

for (i=0;i<8;i++) begin
   randnum = $random();
   j = randnum[QWORD_W+2:QWORD_W+1]; //used for run number
   if (randnum[QWORD_W] == 1'b0) begin
      test_data_ex = old_x[rnd_run[j]] [randnum[QWORD_W-1:0]*64 +:64];
   end else begin
      test_data_ex = old_y[rnd_run[j]] [randnum[QWORD_W-1:0]*64 +:64];
   end

   rnd_addr.run = rnd_run[j];
   rnd_addr.addr = randnum[QWORD_W:0];
      
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


 
