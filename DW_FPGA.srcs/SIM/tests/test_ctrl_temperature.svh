//Vary temperature only

$display("Starting test_ctrl_temperature");

bad_fail_start = bad_fail;

mem_pattern_0(rnd_mem);

ctrl_word              = 'b0;
ctrl_word.cutoff       = {1'b1,{SUM_W{1'b0}}};
ctrl_word.flips        = 3;

ctrl_word.count        = 128;
total_count            = 4 * ctrl_word.count;
			 
ctrl_ladder
  (
   .step_flips(1),
   .step_temperature(0),
   .step_cutoff(0),

   .run_flips(0),
   .run_temperature(1),
   .run_cutoff(0),

   .step_length(4),
   .ctrl_word(ctrl_word),
   .which_runs({NRUNS{1'b1}}),
   
   .reqid(reqid),
   .tag(tag),
   .sys_clk(sys_clk),
   .axi_rx_in(axi_rx_in),
   .axi_rx_out(axi_rx_out)
   );

kick_off
  (
   .start({NRUNS{1'b1}}),
   
   .reqid(reqid),
   .tag(tag),
   .sys_clk(sys_clk),
   .axi_rx_in(axi_rx_in),
   .axi_rx_out(axi_rx_out)
   );


repeat (100 + ((total_count)*NRUNS)) @(negedge sys_clk);

file_csv = $fopen("results.csv","w");

for (i=0;i<NFLIPS;i++) begin
   $fwrite(file_csv,"%6d, %6d, %6d, %6d\n",
	    old_mem_add_0[i],old_mem_add_255[i],old_mem_add_256[i],old_mem_add_511[i]);
end
$fclose(file_csv);
      
// Check that values are within expected range
for (i=0;i<NRUNS;i++) begin
   if ($isunknown({old_mem_add_0[i],
		   old_mem_add_255[i],
		   old_mem_add_256[i],
		   old_mem_add_511[i]
		   })) begin
       $error("***** :( TEST FAILED :( *****");
       $display("Unknowns on the bus.  Refer to waveform.");
   end
   
   @(negedge sys_clk);
   maxerr = $rtoi(2 ** i);
   if (maxerr < 128) begin
      maxerr = 128;
   end
   else if (maxerr > 4096) begin
      maxerr = 4096;
   end
      
   sumerr = old_mem_add_0[i] + (1023 - old_mem_add_255[i]);

   if (old_mem_add_256[i] > 512) begin
      sumerr = sumerr + 1023 - old_mem_add_256[i];
   end else begin
      sumerr = sumerr + old_mem_add_256[i];
   end

   if (old_mem_add_511[i] > 512) begin
      sumerr = sumerr + old_mem_add_511[i] - 512;
   end else begin
      sumerr = sumerr + 512 - old_mem_add_511[i];
   end
   	    
   
   if (sumerr > maxerr) begin
      $error("***** :( TEST FAILED :( *****");
      $display("run %0d sumerr is %0d should be less than %0d", 
	       i,sumerr,maxerr);

      bad_fail = bad_fail + 1;
   end
end // for (i=0;i<NRUNS;i++)

if (bad_fail == bad_fail_start) begin
   $display("*****  :) test_ctrl_temperature PASSED :) *****");
end


 
