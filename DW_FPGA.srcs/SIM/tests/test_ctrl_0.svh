//Program controller, start running

ctrl_word.ctrl1.done 	     = 1'b1;
ctrl_word.ctrl1.flips 	     = 'h2;
ctrl_word.ctrl1.temperature  = 'h3;
ctrl_word.ctrl1.offset 	     = 'h4;
ctrl_word.ctrl0.count 	     = 'h5;

ctrl_addr                    = 'b0;

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

repeat (MAX_RUN_BITS) @(negedge clk_input);

ctrl_cmd      = 'b0;
ctrl_cmd.init = 'b1;

ctrl_addr        = 'b0;
ctrl_addr.is_cmd = 'b1;

pcie_write(CTRL_BAR_START,
	   ctrl_addr,
	   ctrl_cmd,
	   clk_input,
	   bus_pcie_wr);

repeat (MAX_RUN_BITS) @(negedge clk_input);

ctrl_cmd       = 'b0;
ctrl_cmd.start = 'b1;

ctrl_addr        = 'b0;
ctrl_addr.is_cmd = 'b1;

pcie_write(CTRL_BAR_START,
	   ctrl_addr,
	   ctrl_cmd,
	   clk_input,
	   bus_pcie_wr);

repeat (10 * MAX_RUN_BITS) @(negedge clk_input);



