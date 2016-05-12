//Program controller, start running

mem_pattern_0();

// force_pattern_0(clk_input);

ctrl_word.ctrl1.next 	     = 'b0;
ctrl_word.ctrl1.flips 	     = 'h2;
ctrl_word.ctrl1.temperature  = 'h3;
ctrl_word.ctrl0.count 	     = 100;

ctrl_addr = 'b0;

pcie_write(CTRL_BAR_START,
	   ctrl_addr,
	   ctrl_word.ctrl0,
	   clk_input,
	   bus_pcie_wr);

ctrl_addr.ctrl1	     = 'b1;

pcie_write(CTRL_BAR_START,
	   ctrl_addr,
	   ctrl_word.ctrl1,
	   clk_input,
	   bus_pcie_wr);

ctrl_addr     = 'b0;
ctrl_addr.run = MAX_RUN_BITS/2;

pcie_write(CTRL_BAR_START,
	   ctrl_addr,
	   ctrl_word.ctrl0,
	   clk_input,
	   bus_pcie_wr);

ctrl_addr.ctrl1	     = 'b1;

pcie_write(CTRL_BAR_START,
	   ctrl_addr,
	   ctrl_word.ctrl1,
	   clk_input,
	   bus_pcie_wr);

ctrl_addr     = 'b0;
ctrl_addr.run = MAX_RUN_BITS;

pcie_write(CTRL_BAR_START,
	   ctrl_addr,
	   ctrl_word.ctrl0,
	   clk_input,
	   bus_pcie_wr);

ctrl_addr.ctrl1	     = 'b1;

pcie_write(CTRL_BAR_START,
	   ctrl_addr,
	   ctrl_word.ctrl1,
	   clk_input,
	   bus_pcie_wr);

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
		 ('b1 << (MAX_RUN_BITS/2)) | 
		 ('b1 << MAX_RUN_BITS);

ctrl_addr        = 'b0;
ctrl_addr.is_cmd = 'b1;

pcie_write(CTRL_BAR_START,
	   ctrl_addr,
	   ctrl_cmd,
	   clk_input,
	   bus_pcie_wr);

repeat (50 + 100*(MAX_RUN_BITS+1)/2) @(negedge clk_input);




