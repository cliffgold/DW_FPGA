//Vary flips and temperature.  cutoff TBD.
mem_pattern_0(rnd_mem);

rnd_run[0] = 0;
rnd_run[1] = (NRUNS-1)/2;
rnd_run[2] = NRUNS-1;
rnd_run[3] = (NRUNS-1)/3;

//run 0 - flips low (lots of flips), temperature low
ctrl_word.word0.next 	     = 'b0;
ctrl_word.word0.flips        = 'h0;
ctrl_word.word0.temperature  = 'h0;
ctrl_word.word0.cutoff       = {1'b1,{SUM_W{1'b0}}};
ctrl_word.word1.count        = 128;

ctrl_addr     = 0;
ctrl_addr.run = rnd_run[0];

pcie_ctrl_write(CTRL_BAR_START,
		ctrl_addr,
		ctrl_word,
		clk_input,
		bus_pcie_wr);

//run[1]=9 - flips low (lots of flips), temperature high
ctrl_word.next 	       = 'b0;
ctrl_word.flips        = 'h0;
ctrl_word.temperature  = 'hb;
ctrl_word.count        = 128;

ctrl_word.word0.next 	     = 'b0;
ctrl_word.word0.flips        = 'h0;
ctrl_word.word0.temperature  = 'hb;
ctrl_word.word0.cutoff       = {1'b1,{SUM_W{1'b0}}};
ctrl_word.word1.count        = 128;

ctrl_addr     = 0;
ctrl_addr.run = rnd_run[1];

pcie_ctrl_write(CTRL_BAR_START,
		ctrl_addr,
		ctrl_word,
		clk_input,
		bus_pcie_wr);

//run[2]=19 - flips high (few flips), temperature low
ctrl_word.word0.next 	     = 'b0;
ctrl_word.word0.flips        = 'h3;
ctrl_word.word0.temperature  = 'h0;
ctrl_word.word0.cutoff       = {1'b1,{SUM_W{1'b0}}};
ctrl_word.word1.count        = 128;

ctrl_addr     = 0;
ctrl_addr.run = rnd_run[2];

pcie_ctrl_write(CTRL_BAR_START,
		ctrl_addr,
		ctrl_word,
		clk_input,
		bus_pcie_wr);

//run[3]=6 - flips high (few flips), temperature high
ctrl_word.word0.next 	     = 'b0;
ctrl_word.word0.flips        = 'h3;
ctrl_word.word0.temperature  = 'hb;
ctrl_word.word0.cutoff       = {1'b1,{SUM_W{1'b0}}};
ctrl_word.word1.count        = 128;

ctrl_addr     = 0;
ctrl_addr.run = rnd_run[3];

pcie_ctrl_write(CTRL_BAR_START,
		ctrl_addr,
		ctrl_word,
		clk_input,
		bus_pcie_wr);

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

repeat (100 + (128*NRUNS/2)) @(negedge clk_input);



 
