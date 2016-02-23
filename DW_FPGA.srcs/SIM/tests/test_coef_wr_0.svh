//Test a single coef memory write

pcie_cmem.sel = 'h45;
pcie_cmem.addr = 'h123;

pcie_write(COEF_BAR_START,
	   pcie_cmem,
	   64'h321,clk_in,bus_pcie_wr);



