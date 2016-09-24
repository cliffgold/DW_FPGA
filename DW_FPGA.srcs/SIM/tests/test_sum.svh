//Check sum circuit
//Fill each memory with a different constant pattern
//Then, no matter what the XY's, sum should be the same
$display("starting test_sum");

ctrl_word.next 	       = 'b0;
ctrl_word.flips        = 'h0;
ctrl_word.temperature  = 'h0;
ctrl_word.cutoff       = {1'b1,{SUM_W{1'b0}}};
ctrl_word.count        = 10;
total_count            = ctrl_word.count;

axi_data[0]            = ctrl_word[31:0];
axi_data[1]            = ctrl_word[63:32];
axi_data[2]            = ctrl_word[CTRL_WORD_S_W:64];

ctrl_addr 	       = 0;

for (i=0;i<NRUNS;i++) begin
   ctrl_addr.run= i;
   
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

end // for (i=0;i<NRUNS;i++)

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

   poke_cmem(coef_mem);
   
   kick_off(
	    .start({NRUNS{1'b1}}),
	    
	    .reqid(reqid),
	    .tag(tag),
	    .sys_clk(sys_clk),
	    .axi_rx_in(axi_rx_in),
	    .axi_rx_out(axi_rx_out)
	    );
   
   repeat (100 + ((total_count)*NRUNS)) @(negedge sys_clk);
   
// Check that values are === sum
   for (i=0;i<NRUNS;i++) begin
      
      axi_read(.bar(NOSE_BAR),
	       .addr(i),
	       .len(1),
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
   
      test_sum = $signed(axi_data[0][SUM_W:0]);
            
      if (test_sum !== test_ex_sum) begin
	 $error("***** :( TEST FAILED :( *****");
	 $display("Pattern %0d, Run %0d, sum was %0d, expected %0d",
		  k,i,$signed(test_sum),test_ex_sum);
	 
	 bad_fail = bad_fail + 1;
      end
   end // for (i=0;i<NRUNS;i++)
end // for (k=0;k<3;k++)

if (bad_fail == 0) begin
   $display("*****  :) test_sum PASSED :) *****");
end
