//Vary flips and temperature.  cutoff TBD.
$display("Starting test_ctrl_2");

mem_pattern_0(rnd_mem);

rnd_run[0] = 0;
rnd_run[1] = (NRUNS-1)/2;
rnd_run[2] = NRUNS-1;
rnd_run[3] = (NRUNS-1)/3;

//run 0 - flips low (lots of flips), temperature low
ctrl_word.next 	       = 'b0;
ctrl_word.flips        = 'h0;
ctrl_word.temperature  = 'h0;
ctrl_word.cutoff       = {1'b1,{SUM_W{1'b0}}};
ctrl_word.count        = 128;
total_count            = ctrl_word.count;

axi_data[0]            = ctrl_word[31:0];
axi_data[1]            = ctrl_word[63:32];
axi_data[2]            = ctrl_word[CTRL_WORD_S_W:64];

ctrl_addr     = 0;
ctrl_addr.run = rnd_run[0];

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

//run[1]=9 - flips low (lots of flips), temperature high
ctrl_word.next 	       = 'b0;
ctrl_word.flips        = 'h0;
ctrl_word.temperature  = 'hb;
ctrl_word.cutoff       = {1'b1,{SUM_W{1'b0}}};
ctrl_word.count        = 128;

//4 runs occur in parallel - no need to sum up count
//total_count            = total_count + ctrl_word.count;

axi_data[0]            = ctrl_word[31:0];
axi_data[1]            = ctrl_word[63:32];
axi_data[2]            = ctrl_word[CTRL_WORD_S_W:64];

ctrl_addr     = 0;
ctrl_addr.run = rnd_run[1];

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

//run[2]=19 - flips high (few flips), temperature low
ctrl_word.next 	     = 'b0;
ctrl_word.flips        = 'h3;
ctrl_word.temperature  = 'h0;
ctrl_word.cutoff       = {1'b1,{SUM_W{1'b0}}};
ctrl_word.count        = 128;

//4 runs occur in parallel - no need to sum up count
//total_count            = total_count + ctrl_word.count;

axi_data[0]            = ctrl_word[31:0];
axi_data[1]            = ctrl_word[63:32];
axi_data[2]            = ctrl_word[CTRL_WORD_S_W:64];

ctrl_addr     = 0;
ctrl_addr.run = rnd_run[2];

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

//run[3]=6 - flips high (few flips), temperature high
ctrl_word.next 	       = 'b0;
ctrl_word.flips        = 'h3;
ctrl_word.temperature  = 'hb;
ctrl_word.cutoff       = {1'b1,{SUM_W{1'b0}}};
ctrl_word.count        = 128;

//4 runs occur in parallel - no need to sum up count
//total_count            = total_count + ctrl_word.count;

axi_data[0]            = ctrl_word[31:0];
axi_data[1]            = ctrl_word[63:32];
axi_data[2]            = ctrl_word[CTRL_WORD_S_W:64];

ctrl_addr     = 0;
ctrl_addr.run = rnd_run[3];

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

$display("Test test_ctrl_2 complete.  Manually check results");
