//Program controller, start running

mem_pattern_0(rnd_mem);

ctrl_word.next 	       = 'b0;
ctrl_word.flips        = 'h2;
ctrl_word.temperature  = 'h3;
ctrl_word.cutoff       = {1'b1,{SUM_W{1'b0}}};
ctrl_word.count        = 'h5;

ctrl_addr 	       = 'b0;

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

kick_off(
	 .start('b1),	 
	  
	 .reqid(reqid),
	 .tag(tag),
	 .sys_clk(sys_clk),
	 .axi_rx_in(axi_rx_in),
	 .axi_rx_out(axi_rx_out)
	 );


repeat ((5+5) * NRUNS) @(negedge sys_clk);




