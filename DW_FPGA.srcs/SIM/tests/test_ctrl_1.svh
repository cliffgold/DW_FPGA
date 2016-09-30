//Normal Run
$display("Starting test test_ctrl_1");

bad_fail_start = bad_fail;

mem_pattern_0(rnd_mem);

total_count            = 0;

ctrl_word.next 	       = 'b1;
ctrl_word.flips        = 'h1;
ctrl_word.temperature  = 'h0;
ctrl_word.cutoff       = {1'b1,{SUM_W{1'b0}}};
ctrl_word.count        = 64;
total_count            = total_count + ctrl_word.count;

axi_data[0]            = ctrl_word[31:0];
axi_data[1]            = ctrl_word[63:32];
axi_data[2]            = ctrl_word[CTRL_WORD_S_W:64];

rnd_run[0] 	       = 0;
rnd_run[1] 	       = (NRUNS-1)/2;
rnd_run[2] 	       = NRUNS-1;
rnd_run[3] 	       = (NRUNS-1)/3;

ctrl_addr 	       = 0;

for (i=0;i<4;i++) begin
   ctrl_addr.run      = rnd_run[i];
   
   axi_write(.bar(FREAK_BAR),
	     .addr(ctrl_addr),
	     .data(axi_data),
	     .len(3),
	     .wdat(1),
	     
	     .reqid(reqid),
	     .tag(tag),
	     .sys_clk(sys_clk),
	     .axi_rx_in(axi_rx_in),
	     .axi_rx_out(axi_rx_out)
	     );
end

ctrl_word.next 	       = 'b1;
ctrl_word.flips        = 'h3;
ctrl_word.temperature  = 'h0;
ctrl_word.cutoff       = {1'b1,{SUM_W{1'b0}}};
ctrl_word.count        = 128;
total_count            = total_count + ctrl_word.count;

axi_data[0]            = ctrl_word[31:0];
axi_data[1]            = ctrl_word[63:32];
axi_data[2]            = ctrl_word[CTRL_WORD_S_W:64];

rnd_run[0] 	       = 0;
rnd_run[1] 	       = (NRUNS-1)/2;
rnd_run[2] 	       = NRUNS-1;
rnd_run[3] 	       = (NRUNS-1)/3;

ctrl_addr 	       = 0;
ctrl_addr.addr         = 1;

for (i=0;i<4;i++) begin
   ctrl_addr.run      = rnd_run[i];
   
   axi_write(.bar(FREAK_BAR),
	     .addr(ctrl_addr),
	     .data(axi_data),
	     .len(3),
	     .wdat(1),
	     
	     .reqid(reqid),
	     .tag(tag),
	     .sys_clk(sys_clk),
	     .axi_rx_in(axi_rx_in),
	     .axi_rx_out(axi_rx_out)
	     );
end

ctrl_word.next 	       = 'b0;
ctrl_word.flips        = 'h5;
ctrl_word.temperature  = 'h0;
ctrl_word.cutoff       = {1'b1,{SUM_W{1'b0}}};
ctrl_word.count        = 512;
total_count            = total_count + ctrl_word.count;

axi_data[0]            = ctrl_word[31:0];
axi_data[1]            = ctrl_word[63:32];
axi_data[2]            = ctrl_word[CTRL_WORD_S_W:64];

rnd_run[0] 	       = 0;
rnd_run[1] 	       = (NRUNS-1)/2;
rnd_run[2] 	       = NRUNS-1;
rnd_run[3] 	       = (NRUNS-1)/3;

ctrl_addr 	       = 0;
ctrl_addr.addr         = 2;

for (i=0;i<4;i++) begin
   ctrl_addr.run      = rnd_run[i];
   
   axi_write(.bar(FREAK_BAR),
	     .addr(ctrl_addr),
	     .data(axi_data),
	     .len(3),
	     .wdat(1),
	     
	     .reqid(reqid),
	     .tag(tag),
	     .sys_clk(sys_clk),
	     .axi_rx_in(axi_rx_in),
	     .axi_rx_out(axi_rx_out)
	     );

end

kick_off(
	 .start('b1 | 
		 ('b1 << ((NRUNS-1)/3)) | 
		 ('b1 << ((NRUNS-1)/2)) | 
		 ('b1 << (NRUNS-1))),
	 
	  
	 .reqid(reqid),
	 .tag(tag),
	 .sys_clk(sys_clk),
	 .axi_rx_in(axi_rx_in),
	 .axi_rx_out(axi_rx_out)
	 );


repeat (100 + ((total_count)*NRUNS)) @(negedge sys_clk);

// Check that values are within expected range
maxerr = 24;

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
   
   rnd_addr.run = rnd_run[j];
   rnd_addr.addr = randnum[QWORD_W:0];

   axi_read(.bar(RANDY_BAR),
	    .addr(rnd_addr),
	    .len(2),
	    .data(axi_data),
	    
	    .reqid(reqid),
	    .tag(tag),
	    .cpl_id(cpl_id_ex),
	    .sys_clk(sys_clk),
	    .axi_rx_in(axi_rx_in),
	    .axi_rx_out(axi_rx_out),
	    .axi_tx_in(axi_tx_in),
	    .axi_tx_out(axi_tx_out)
	    );
   
   test_data_rd = {axi_data[1],axi_data[0]};

   if (randnum[QWORD_W:0] == {(QWORD_W){1'b1}}) begin
      test_data_ex[31:0]  = old_x[rnd_run[j]] [randnum[QWORD_W-1:0]*32 +:32];
      test_data_ex[63:32] = old_y[rnd_run[j]] [31:0];
   end
   else if (randnum[QWORD_W:0] == {(QWORD_W+1){1'b1}}) begin
      test_data_ex[31:0]  = old_y[rnd_run[j]] [randnum[QWORD_W-1:0]*32 +:32];
      test_data_ex[63:32] = old_x[rnd_run[j]] [31:0];
   end
   else if (randnum[QWORD_W] == 1'b0) begin
      test_data_ex = old_x[rnd_run[j]] [randnum[QWORD_W-1:0]*32 +:64];
   end else begin
      test_data_ex = old_y[rnd_run[j]] [randnum[QWORD_W-1:0]*32 +:64];
   end
   
   if (test_data_rd !== test_data_ex) begin
      $error("***** :( TEST FAILED :( *****\n Read xy does not match expected for %0x:%0x run %0d expected %0x got %0x",
	     rnd_addr.addr*32+63,
	     rnd_addr.addr*32,
	     rnd_addr.run,
	     test_data_ex,test_data_rd);
      bad_fail = bad_fail + 1;
   end
end // for (i=0;i<3;i++)

if (bad_fail == bad_fail_start) begin
   $display("*****  :) test_ctrl_1 PASSED :) *****");
end


 
