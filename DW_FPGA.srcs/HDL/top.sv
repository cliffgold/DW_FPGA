//Top level module
`include "timescale.svh"

module top
  (pclk_p,
   pclk_n,
   prst_n,
   
   tx_p,
   tx_n,

   rx_p,
   rx_n
   );
   
`include "params.svh"
`include "structs.svh"

   input               pclk_p;  //pcie reference clock
   input               pclk_n;

   input               prst_n;    //major reset
   
   input [LANE_W:0]    rx_p;
   input [LANE_W:0]    rx_n;
 
   output [LANE_W:0]   tx_p;
   output [LANE_W:0]   tx_n;
 
   sum_pick_s  sum_pick;
   
   block_pcie_s  coef_pcie;
   block_pcie_s  pick_pcie;
   block_pcie_s  rnd_pcie; 
                        
   pcie_block_s  pcie_coef;
   pcie_block_s  pcie_pick;
   pcie_block_s  pcie_rnd;
   pcie_block_s  pcie_ctrl;

   ctrl_rnd_s  ctrl_rnd;
   ctrl_pick_s ctrl_pick;
   
   rnd_coef_s  rnd_coef;
   coef_sum_s  coef_sum;

   pick_rnd_s  pick_rnd;
   
   sys_s       sys;

   wire        pcie_ref_clk;
   wire        pcie_rst_n;
   wire        user_reset_out;
   wire        user_lnk_up;
   wire        user_clk_out;
   

   clk_gen clk_gen_0
     (
      .pclk_p       (pclk_p),
      .pclk_n       (pclk_n),
      .pcie_ref_clk (pcie_ref_clk),
      
      .prst_n     (prst_n),
      .pcie_rst_n (pcie_rst_n),
      
      .user_reset_out(user_reset_out),
      .user_lnk_up   (user_lnk_up),
      .user_clk_out  (user_clk_out),
      .sys           (sys)
      );
         
   pcie pcie_0
     (
      .sys(sys),

      .tx_p(tx_p),
      .tx_n(tx_n),

      .rx_p(rx_p),
      .rx_n(rx_n),

      .user_reset_out(user_reset_out),
      .user_lnk_up   (user_lnk_up),
      .user_clk_out  (user_clk_out),

      .pcie_ref_clk(pcie_ref_clk),
      .pcie_rst_n(pcie_rst_n),

      .coef_pcie(coef_pcie), 
      .pick_pcie(pick_pcie),
      .rnd_pcie(rnd_pcie),
          
      .pcie_coef(pcie_coef),
      .pcie_pick(pcie_pick),
      .pcie_rnd (pcie_rnd ),
      .pcie_ctrl(pcie_ctrl)
      );   
   
   ctrl ctrl_0
     (
      .sys(sys),
      .pcie_ctrl(pcie_ctrl),

      .ctrl_rnd(ctrl_rnd),
      .ctrl_pick(ctrl_pick)
      );

   rnd rnd_0
     (
      .sys(sys),      
      .pcie_rnd(pcie_rnd),
      .rnd_pcie(rnd_pcie),
      .ctrl_rnd(ctrl_rnd),
      .pick_rnd(pick_rnd),

      .rnd_coef(rnd_coef)
      );

   coef
     #(.IS_SIM(IS_SIM)) 
     coef_0
    ( 
     .sys(sys),
     .rnd_coef(rnd_coef),
     .pcie_coef(pcie_coef),

     .coef_pcie(coef_pcie),
     .coef_sum(coef_sum)
     );

   sum sum_0
     (
      .sys(sys),      
      .coef_sum(coef_sum),

      .sum_pick(sum_pick)
      );

   pick pick_0
     (
      .sys(sys),
      .ctrl_pick(ctrl_pick),
      .sum_pick(sum_pick),
      .pcie_pick(pcie_pick),

      .pick_rnd(pick_rnd),
      .pick_pcie(pick_pcie)
      );
   

endmodule // top


 
