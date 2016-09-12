// Module to interface to the future Xilinx PCIE block

`include "timescale.svh"

module pcie
  (sys,

   pcie_ref_clk,
   pcie_rst_n,
   
   tx_p,
   tx_n,

   rx_p,
   rx_n,

   user_reset_out,
   user_lnk_up,
   user_clk_out,


   coef_pcie,
   pick_pcie,
   rnd_pcie,

   pcie_coef,
   pcie_pick,
   pcie_rnd,
   pcie_ctrl
   );
   
`include "params.svh"
`include "structs.svh"
   
   input   sys_s      sys;

   input               pcie_ref_clk;  //pcie reference clock
   input               pcie_rst_n;    //major reset
   
   input [LANE_W:0]    rx_p;
   input [LANE_W:0]    rx_n;
 
   output [LANE_W:0]   tx_p;
   output [LANE_W:0]   tx_n;

   output 	       user_reset_out;
   output 	       user_lnk_up;
   output 	       user_clk_out;
   
   input   block_pcie_s  coef_pcie;
   input   block_pcie_s  pick_pcie;
   input   block_pcie_s  rnd_pcie;

   output  pcie_block_s  pcie_coef;
   output  pcie_block_s  pcie_pick;
   output  pcie_block_s  pcie_rnd;
   output  pcie_block_s  pcie_ctrl;
   
   pcie_cpl_id_s cpl_id;

   axi_rx_in_s      axi_rx_in; 
   axi_rx_out_s     axi_rx_out;
   axi_tx_in_s      axi_tx_in; 
   axi_tx_out_s     axi_tx_out;

   axi_decoder axi_decoder_0
     (
      .sys(sys),
      
      .cpl_id(cpl_id),

      .axi_rx_in(axi_rx_in),
      .axi_rx_out(axi_rx_out),
      .axi_tx_in(axi_tx_in),
      .axi_tx_out(axi_tx_out),

      .coef_pcie(coef_pcie),
      .pick_pcie(pick_pcie),
      .rnd_pcie(rnd_pcie),
 
      .pcie_coef(pcie_coef),
      .pcie_pick(pcie_pick),
      .pcie_rnd (pcie_rnd),
      .pcie_ctrl(pcie_ctrl)
      );
      
pcie_7x_0 pcie_inst (
  .pci_exp_txp(tx_p),   // output[3 : 0]
  .pci_exp_txn(tx_n),   // output[3 : 0]
  .pci_exp_rxp(rx_p),   // input[3 : 0]
  .pci_exp_rxn(rx_n),   // input[3 : 0]
		     
  .user_clk_out(user_clk_out),     // output
  .user_reset_out(user_reset_out), // output
  .user_lnk_up(user_lnk_up),       // output
  .user_app_rdy(    ),             // output
		     
  .tx_buf_av(axi_tx_out.buf_av),  // output[5 : 0]
  .tx_cfg_req(      ),            // output
  .tx_err_drop(     ),            // output
		     
  .s_axis_tx_tready(axi_tx_out.tready), // output
  .s_axis_tx_tdata(axi_tx_in.tdata),    // input[63 : 0]
  .s_axis_tx_tkeep(axi_tx_in.tkeep),    // input[7 : 0]
  .s_axis_tx_tlast(axi_tx_in.tlast),    // input
  .s_axis_tx_tvalid(axi_tx_in.tvalid),  // input
  .s_axis_tx_tuser(axi_tx_in.tuser),    // input[3 : 0]
  .m_axis_rx_tdata(axi_rx_out.tdata),   // output[63 : 0]
  .m_axis_rx_tkeep(axi_rx_out.tkeep),   // output[7 : 0]
  .m_axis_rx_tlast(axi_rx_out.tlast),   // output
  .m_axis_rx_tvalid(axi_rx_out.tvalid), // output
  .m_axis_rx_tready(axi_rx_in.tready),  // input
  .m_axis_rx_tuser(axi_rx_out.tuser),   // output[21 : 0]
		     
  .cfg_status(     ),               // output[15 : 0]
  .cfg_command(     ),              // output[15 : 0]
  .cfg_dstatus(     ),              // output[15 : 0]
  .cfg_dcommand(     ),             // output[15 : 0]
  .cfg_lstatus(     ),              // output[15 : 0]
  .cfg_lcommand(     ),             // output[15 : 0]
  .cfg_dcommand2(     ),            // output[15 : 0]
  .cfg_pcie_link_state(     ),      // output[2 : 0]
  .cfg_pmcsr_pme_en(     ),         // output
  .cfg_pmcsr_powerstate(     ),     // output[1 : 0]
  .cfg_pmcsr_pme_status(     ),     // output
  .cfg_received_func_lvl_rst(     ),// output
  .cfg_interrupt(1'b0),             // input
  .cfg_interrupt_rdy(     ),        // output
  .cfg_interrupt_assert(1'b0 ),     // input
  .cfg_interrupt_di(8'b0     ),     // input[7 : 0]
  .cfg_interrupt_do(     ),         // output[7 : 0]
  .cfg_interrupt_mmenable(     ),   // output[2 : 0]
  .cfg_interrupt_msienable(     ),  // output
  .cfg_interrupt_msixenable(     ), // output
  .cfg_interrupt_msixfm(     ),     // output
  .cfg_interrupt_stat(1'b0  ),      // input
  .cfg_pciecap_interrupt_msgnum(5'b0 ), // input[4 : 0]
  .cfg_to_turnoff(     ),           // output
		     
  .cfg_bus_number(cpl_id.bn),       // output[7 : 0]
  .cfg_device_number(cpl_id.dn),    // output[4 : 0]
  .cfg_function_number(cpl_id.fn),  // output[2 : 0]
		     
  .cfg_bridge_serr_en(     ),                         // output
		     
  .cfg_slot_control_electromech_il_ctl_pulse(     ),  // output
  .cfg_root_control_syserr_corr_err_en(     ),        // output
  .cfg_root_control_syserr_non_fatal_err_en(     ),   // output
  .cfg_root_control_syserr_fatal_err_en(     ),       // output
  .cfg_root_control_pme_int_en(     ),                // output
		     
  .cfg_aer_rooterr_corr_err_reporting_en(     ),      // output
  .cfg_aer_rooterr_non_fatal_err_reporting_en(     ), // output
  .cfg_aer_rooterr_fatal_err_reporting_en(     ),     // output
  .cfg_aer_rooterr_corr_err_received(     ),          // output
  .cfg_aer_rooterr_non_fatal_err_received(     ),     // output
  .cfg_aer_rooterr_fatal_err_received(     ),         // output
		     
  .cfg_vc_tcvc_map(     ),                            // output[6 : 0]
		     
  .sys_clk(pcie_ref_clk),   // input
  .sys_rst_n(pcie_rst_n)    // input
);


endmodule // pcie

     
