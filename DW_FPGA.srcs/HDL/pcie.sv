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

   coef_pcie,
   pick_pcie,
   rnd_pcie,

   pcie_coef,
   pcie_ctrl
   );
   
`include "params.svh"
`include "structs.svh"
   
   output  sys_s      sys;

   input               pcie_ref_clk;  //pcie reference clock
   input               pcie_rst_n;    //major reset
   
   input [LANE_W:0]    rx_p;
   input [LANE_W:0]    rx_n;
 
   output [LANE_W:0]   tx_p;
   output [LANE_W:0]   tx_n;
    
   input   block_pcie_s  coef_pcie;
   input   block_pcie_s  pick_pcie;
   input   block_pcie_s  rnd_pcie;

   output  pcie_block_s  pcie_coef;
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
      .pcie_ctrl(pcie_ctrl)
      );
      
pcie_7x_0 pcie_inst (
    //-------------------------------------------------------//
    // 1. PCI Express (pci_exp) Interface                    //
    //-------------------------------------------------------//

    // Tx
    .pci_exp_txp                  (tx_p                  ), // O [7:0]
    .pci_exp_txn                  (tx_n                  ), // O [7:0]

    // Rx
    .pci_exp_rxp                  (rx_p                  ), // I [7:0]
    .pci_exp_rxn                  (rx_n                  ), // I [7:0]

    //------------------------------------------------------//
    // 2. Clocking Interface - For Partial Reconfig Support //
    //------------------------------------------------------//
    .pipe_pclk_in                 (PIPE_PCLK_IN          ),
    .pipe_rxusrclk_in             (PIPE_RXUSRCLK_IN      ),
    .pipe_rxoutclk_in             (PIPE_RXOUTCLK_IN      ),
    .pipe_dclk_in                 (PIPE_DCLK_IN          ),
    .pipe_userclk1_in             (PIPE_USERCLK1_IN      ),
    .pipe_oobclk_in               (PIPE_OOBCLK_IN        ),
    .pipe_userclk2_in             (PIPE_USERCLK2_IN      ),
    .pipe_mmcm_lock_in            (PIPE_MMCM_LOCK_IN     ),
    
    .pipe_txoutclk_out            (PIPE_TXOUTCLK_OUT     ),
    .pipe_rxoutclk_out            (PIPE_RXOUTCLK_OUT     ),
    .pipe_pclk_sel_out            (PIPE_PCLK_SEL_OUT     ),
    .pipe_gen3_out                (PIPE_GEN3_OUT         ),

    //--------------------------------------------------------//
    // 3. AXI-S Interface                                     //
    //--------------------------------------------------------//

    // Common
    .user_clk_out                 (sys.clk              ),
    .user_reset_out               (sys.reset            ),
    .user_lnk_up                  (                     ),

    // Tx
    .tx_buf_av                    (axi_tx_out.buf_av     ), // O
    .tx_err_drop                  (                      ), // O
    .tx_cfg_req                   (                      ), // O
    .s_axis_tx_tready             (axi_tx_out.tready     ), // O 
    .s_axis_tx_tdata              (axi_tx_in.tdata       ), // I [CORE_DATA_WIDTH-1:0]
    .s_axis_tx_tkeep              (axi_tx_in.tkeep       ), // I [CORE_BE_WIDTH-1:0]
    .s_axis_tx_tuser              (axi_tx_in.tuser       ), // I [3:0]
    .s_axis_tx_tlast              (axi_tx_in.tlast       ), // I
    .s_axis_tx_tvalid             (axi_tx_in.tvalid      ), // I

//    .tx_cfg_gnt                   (1'b0                  ), // I

    // Rx
    .m_axis_rx_tdata              (axi_rx_out.tdata      ), // O  [CORE_DATA_WIDTH-1:0]
    .m_axis_rx_tkeep              (axi_rx_out.tkeep      ), // O  [CORE_BE_WIDTH-1:0]
    .m_axis_rx_tlast              (axi_rx_out.tlast      ), // O
    .m_axis_rx_tvalid             (axi_rx_out.tvalid     ), // O
    .m_axis_rx_tready             (axi_rx_in.tready      ), // I  
    .m_axis_rx_tuser              (axi_rx_out.tuser      ), // O  [21:0]
//    .rx_np_ok                     (1'b1                  ), // I
//    .rx_np_req                    (1'b0                  ), // I

    //------------------------------------------------------//
    // 4. Configuration (CFG) Interface                     //
    //------------------------------------------------------//


    .cfg_interrupt                (1'b0  ), // I
    .cfg_interrupt_rdy            (      ), // O
    .cfg_interrupt_assert         (1'b0  ), // I
    .cfg_interrupt_di             (8'b0  ), // I [7:0]
    .cfg_interrupt_do             (      ), // O [7:0]
    .cfg_interrupt_mmenable       (      ), // O [2:0]
    .cfg_interrupt_msienable      (      ), // O 
    .cfg_interrupt_msixenable     (      ), // O
    .cfg_interrupt_msixfm         (      ), // O
    .cfg_interrupt_stat           (1'b0  ),
    .cfg_pciecap_interrupt_msgnum (5'b00000 ),

//    .cfg_to_turnoff       (                     ), // O
//    .cfg_turnoff_ok       (1'b0                 ), // I
    .cfg_bus_number       (cpl_id.bn            ), // O [7:0]
    .cfg_device_number    (cpl_id.dn            ), // O [4:0]
    .cfg_function_number  (cpl_id.fn            ), // O [2:0]
//    .cfg_pm_wake          (cfg_pm_wake          ), // I


    //------------------------------------------------------//
    // 8. System  (SYS) Interface                           //
    //------------------------------------------------------//

    .sys_clk                      (pcie_ref_clk          ), // I
    .pipe_mmcm_rst_n              (1'b1                  ),
    .sys_rst_n                    (pcie_rst_n            )  // I

		     );

endmodule // pcie

     
