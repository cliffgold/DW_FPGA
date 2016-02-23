//Test a single coef memory write/read

pcie_cmem.sel = 'h45;
pcie_cmem.addr = 'h123;
test_data_wr   = 'h321;

pcie_write(COEF_BAR_START,
	   pcie_cmem,
	   64'h321,
	   clk_in,
	   bus_pcie_wr);

pcie_read (COEF_BAR_START,
	   pcie_cmem,
	   test_data_rd,
	   clk_in,
	   bus_pcie_req,
	   pcie_bus_rd);

if (test_data_rd !== test_data_wr) begin
   $error("Read does not match write at addr %0x\n expect %0x got %0x",
	  pcie_cmem,test_data_wr,test_data_rd);
end



