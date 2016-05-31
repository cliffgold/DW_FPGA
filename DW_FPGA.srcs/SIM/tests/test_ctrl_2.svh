//Program controller, start running
mem_pattern_0(rnd_mem);

rnd_run[0] = 0;
rnd_run[1] = (NRUNS-1)/2;
rnd_run[2] = NRUNS-1;
rnd_run[3] = (NRUNS-1)/3;

//run 0 - flips low (lots of flips), temperature low
ctrl_word.ctrl1.next 	     = 'b0;
ctrl_word.ctrl1.flips 	     = 'h0;
ctrl_word.ctrl1.temperature  = 'h0;
ctrl_word.ctrl0.count 	     = 128;

ctrl_addr     = 0;
ctrl_addr.run = rnd_run[0];

pcie_ctrl(
	  ctrl_addr,
	  ctrl_word,
	  clk_input,
	  bus_pcie_wr);

//run[1]=9 - flips low (lots of flips), temperature high
ctrl_word.ctrl1.next 	     = 'b0;
ctrl_word.ctrl1.flips 	     = 'h0;
ctrl_word.ctrl1.temperature  = 'hb;
ctrl_word.ctrl0.count 	     = 128;

ctrl_addr          = 0;
ctrl_addr.run      = rnd_run[1];
ctrl_addr.is_ctrl1 = 1'b0;
   
pcie_ctrl(
	  ctrl_addr,
	  ctrl_word,
	  clk_input,
	  bus_pcie_wr);

//run[2]=19 - flips high (few flips), temperature low
ctrl_word.ctrl1.next 	     = 'b0;
ctrl_word.ctrl1.flips 	     = 'h3;
ctrl_word.ctrl1.temperature  = 'h0;
ctrl_word.ctrl0.count 	     = 128;

ctrl_addr          = 0;
ctrl_addr.run      = rnd_run[2];
ctrl_addr.is_ctrl1 = 1'b0;
   
pcie_ctrl(
	  ctrl_addr,
	  ctrl_word,
	  clk_input,
	  bus_pcie_wr);

//run[3]=6 - flips high (few flips), temperature high
ctrl_word.ctrl1.next 	     = 'b0;
ctrl_word.ctrl1.flips 	     = 'h3;
ctrl_word.ctrl1.temperature  = 'hb;
ctrl_word.ctrl0.count 	     = 128;

ctrl_addr          = 0;
ctrl_addr.run      = rnd_run[3];
ctrl_addr.is_ctrl1 = 1'b0;
   
pcie_ctrl(
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



 
