//Handle pcie reset same as example design

`include "timescale.svh"

module clk_gen
  (
   pclk_p,     
   pclk_n,
   pcie_ref_clk,
   
   prst_n,     
   pcie_rst_n, 

   user_reset_out,
   user_lnk_up,
   user_clk_out,
   sys            
   );

`include "params.svh"
`include "structs.svh"

   input  pclk_p;
   input  pclk_n;
   output pcie_ref_clk;
   
   input  prst_n;
   output pcie_rst_n;
    
   input user_reset_out;
   input user_lnk_up;
   input user_clk_out;
      
   output  sys_s      sys;

   reg 	   user_reset_q;
   reg 	   user_lnk_up_q;
   reg 	   reset;
   reg 	   reset_n;
      
    IBUFDS_GTE2 pclk_ibuf 
     (
      .I      (pclk_p     ),
      .IB     (pclk_n     ),
      .CEB    (1'b0       ),
      .O      (pcie_ref_clk   ),
      .ODIV2  (               )
      );
   
   IBUF prst_n_ibuf 
     (
      .I      (prst_n     ),
      .O      (pcie_rst_n )
      );

   assign sys.clk = user_clk_out;

   always@(posedge sys.clk) begin
      user_reset_q  <= user_reset_out;
      user_lnk_up_q <= user_lnk_up;
   end

   always @(posedge sys.clk) begin
      if (user_reset_q) begin
         reset   <= 1'b1;
         reset_n <= 1'b0;
      end else begin
	 reset   <= ~user_lnk_up_q;
	 reset_n <= user_lnk_up_q;
      end
   end

   BUFG reset_bufg
     (.I(reset),
      .O(sys.reset)
      );
   
   BUFG reset_n_bufg
     (.I(reset_n),
      .O(sys.reset_n)
      );
   
endmodule // pcie_reset
