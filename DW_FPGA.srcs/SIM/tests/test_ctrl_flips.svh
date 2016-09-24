//Vary flips only
$display("Starting test_ctrl_flips");

mem_pattern_0(rnd_mem);

ctrl_word.next 	     = 'b0;
ctrl_word.flips        = 'h0;
ctrl_word.temperature  = 'h0;
ctrl_word.cutoff       = {1'b1,{SUM_W{1'b0}}};
ctrl_word.count        = 256;
total_count            = ctrl_word.count;

ctrl_addr 	       = 0;
ctrl_addr.addr 	       = 0;

for (i=0;i<NFLIPS;i++) begin
   ctrl_addr.run          = i;
   ctrl_word.flips  = i;
   
   axi_data[0]            = ctrl_word[31:0];
   axi_data[1]            = ctrl_word[63:32];
   axi_data[2]            = ctrl_word[CTRL_WORD_S_W:64];

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

end // for (i=0;i<3;i++)

kick_off(
	 .start({NFLIPS{1'b1}}),
	 
	 .reqid(reqid),
	 .tag(tag),
	 .sys_clk(sys_clk),
	 .axi_rx_in(axi_rx_in),
	 .axi_rx_out(axi_rx_out)
	 );
   

repeat (100 + ((total_count)*NRUNS)) @(negedge sys_clk);
   
// Check that values are within expected range

for (i=0;i<NFLIPS;i++) begin
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
   $display("*****  :) test_ctrl_flips PASSED :) *****");
end


 
