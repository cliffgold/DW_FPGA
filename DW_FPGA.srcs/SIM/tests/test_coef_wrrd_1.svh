//Test of some random wr/rds at specific pre-loaded spots
$display("Start test_coef_wrrd_1");
bad_fail_start = bad_fail;

//Set addresses used, and the resepective data

test_coef_sel[0] = 'b0;
test_coef_sel[1] = (NCMEMS/2) -1;
test_coef_sel[2] = NCMEMS/2;
test_coef_sel[3] = NCMEMS-1;

test_coef_addr[0] = 'b0;
test_coef_addr[1] = (NCMEM_ADDRS-1)/2;
test_coef_addr[2] = NCMEM_ADDRS/2;
test_coef_addr[3] = NCMEM_ADDRS-1;

//Note that I had to put fixed numbers for cmem{}.  It seems to need to be a string.
for (i=0;i<4;i=i+1) begin
   randnum = $random();
   sim_top.top_0.coef_0.\cmem[0].coef_mem_0 .inst.\native_mem_module.blk_mem_gen_v8_3_3_inst .memory[test_coef_addr[i]] = randnum[CMEM_DATA_W:0];
   test_coef_data[0][i] = randnum[CMEM_DATA_W:0];
//   $display("mem %0x addr %0x got %0x",0,test_coef_addr[i],randnum[CMEM_DATA_W:0]);
   
   randnum = $random();
   sim_top.top_0.coef_0.\cmem[255].coef_mem_0 .inst.\native_mem_module.blk_mem_gen_v8_3_3_inst .memory[test_coef_addr[i]] = randnum[CMEM_DATA_W:0];
   test_coef_data[1][i] = randnum[CMEM_DATA_W:0];
   
   randnum = $random();
   sim_top.top_0.coef_0.\cmem[256].coef_mem_0 .inst.\native_mem_module.blk_mem_gen_v8_3_3_inst .memory[test_coef_addr[i]] = randnum[CMEM_DATA_W:0];
   test_coef_data[2][i] = randnum[CMEM_DATA_W:0];
   
   randnum = $random();
   sim_top.top_0.coef_0.\cmem[511].coef_mem_0 .inst.\native_mem_module.blk_mem_gen_v8_3_3_inst .memory[test_coef_addr[i]] = randnum[CMEM_DATA_W:0];
   test_coef_data[3][i] = randnum[CMEM_DATA_W:0];

end

for (i=0;i<256;i=i+1) begin
   randnum 	   = $random();
   coef_addr.sel   = test_coef_sel[randnum[1:0]];
   coef_addr.addr  = test_coef_addr[randnum[3:2]];

   axi_data[0]     = randnum[CMEM_DATA_W+5:5];
   test_data_ex    = test_coef_data[randnum[1:0]][randnum[3:2]];

   if (randnum[4]) begin
      axi_write(.bar(COFFEE_BAR),
		.addr(coef_addr),
		.data(axi_data),
		.len(1),
		.wdat(1),
		
		.reqid(reqid),
		.tag(tag),
		.sys_clk(sys_clk),
		.axi_rx_in(axi_rx_in),
		.axi_rx_out(axi_rx_out)
		);
      
      
      test_coef_data[randnum[1:0]][randnum[3:2]] = axi_data[0];
   end else begin
      
      axi_read(.bar(COFFEE_BAR),
	       .addr(coef_addr),
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

      if (axi_data[0] !== test_data_ex) begin
	 $error("***** :( TEST FAILED :( *****\n Read does not match write for mem %0x at addr %0x\n expect %0x got %0x",
		coef_addr.sel,coef_addr.addr,test_data_ex,axi_data[0]);
	 bad_fail = bad_fail + 1;
      end
   end // else: !if(randnum[4])
end // for (i=0;i<100;i=i+1)

if (bad_fail == bad_fail_start) begin
  $display("***:) YES! PASSED coef_wrrd_1 :)***");
end






