//Test of some random wr/rds at specific pre-loaded spots

//Set addresses used, and the resepective data

test_coef_sel[0] = 'b0;
test_coef_sel[1] = MAX_CMEM/2;
test_coef_sel[2] = 1 + MAX_CMEM/2;
test_coef_sel[3] = MAX_CMEM;

test_coef_addr[0] = 'b0;
test_coef_addr[1] = MAX_CMEM_ADDR_BITS/2;
test_coef_addr[2] = 1 + (MAX_CMEM_ADDR_BITS/2);
test_coef_addr[3] = MAX_CMEM_ADDR_BITS;

//memory (sel) 0 has all 0's
test_coef_data[0][0] = 'b0;
test_coef_data[0][1] = 'b0;
test_coef_data[0][2] = 'b0;
test_coef_data[0][3] = 'b0;

//memory 1 has alternating pattern
test_coef_data[1][0] = 2047;
test_coef_data[1][1] = -2048;
test_coef_data[1][2] = 2047;
test_coef_data[1][3] = -2048;

//memory 2 data = addr
test_coef_data[2][0] = test_coef_addr[0];
test_coef_data[2][1] = test_coef_addr[1];
test_coef_data[2][2] = test_coef_addr[2];
test_coef_data[2][3] = test_coef_addr[3];

//memory 3 data = -1 - addr
test_coef_data[3][0] = -1 - test_coef_addr[0];
test_coef_data[3][1] = -1 - test_coef_addr[1];
test_coef_data[3][2] = -1 - test_coef_addr[2];
test_coef_data[3][3] = -1 - test_coef_addr[3];


for (i=0;i<100;i=i+1) begin
   randnum = $random();
   pcie_coef_addr.sel  = test_coef_sel[randnum[1:0]];
   pcie_coef_addr.addr = test_coef_addr[randnum[3:2]];
   test_data_wr        = randnum[MAX_CMEM_DATA+5:5];
   test_data_ex        = test_coef_data[randnum[1:0]][randnum[3:2]];

   if (randnum[4]) begin
      pcie_write(COEF_BAR_START,
		 pcie_coef_addr,
		 test_data_wr,
		 clk_input,
		 bus_pcie_wr);
      
      test_coef_data[randnum[1:0]][randnum[3:2]] = test_data_wr;
   end else begin
      
      pcie_read (COEF_BAR_START,
		 pcie_coef_addr,
		 test_data_rd,
		 clk_input,
		 bus_pcie_req,
		 pcie_bus_rd);

      if (test_data_rd !== test_data_ex) begin
	 $error("***** :( TEST FAILED :( *****\n Read does not match write at addr %0x\n expect %0x got %0x",
		pcie_coef_addr,test_data_ex,test_data_rd);
	 bad_fail = bad_fail + 1;
	 $finish;
      end
   end // else: !if(randnum[4])
end // for (i=0;i<100;i=i+1)

$display("***:) YES! PASSED coef_wrrd_1 :)***");





