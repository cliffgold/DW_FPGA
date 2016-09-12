//Break out the axi bus to the individual blocks

module axi_decoder
  (sys,

   cpl_id,

   axi_rx_in,
   axi_rx_out,
   axi_tx_in,
   axi_tx_out,

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
      
   localparam IDLE_ST          = 4'h0;
   localparam WR_START_ST      = 4'h1;
   localparam WR_W0_ST	       = 4'h2;
   localparam WR_W1_ST	       = 4'h3;
   localparam CPL_US_SU_ST     = 4'h4;
   localparam CPL_US0_ST       = 4'h5;
   localparam CPL_US1_ST       = 4'h6;
   localparam CPL_US2_ST       = 4'h7;
   localparam RD_SU_ST	       = 4'h8;
   localparam RD_CPL_START_ST  = 4'h9;
   localparam RD_CPL0_ST       = 4'ha;
   localparam RD0_ST	       = 4'hb;
   localparam RD1_ST	       = 4'hc;
   
   
   input   sys_s            sys;
   input   pcie_cpl_id_s    cpl_id;
   
   output  axi_rx_in_s      axi_rx_in;
   input   axi_rx_out_s     axi_rx_out;
   output  axi_tx_in_s      axi_tx_in;
   input   axi_tx_out_s     axi_tx_out;
  
   input   block_pcie_s  coef_pcie;
   input   block_pcie_s  pick_pcie;
   input   block_pcie_s  rnd_pcie;

   output   pcie_block_s  pcie_coef;
   output   pcie_block_s  pcie_pick;
   output   pcie_block_s  pcie_rnd;
   output   pcie_block_s  pcie_ctrl;
       
   pcie_hdr_s pcie_hdr;
   pcie_hdr_s axi_rx_out_hdr;
   pcie_qw1_s axi_rx_out_w1;

   pcie_cpl_qw0_s pcie_cpl_qw0;
   pcie_cpl_dw2_s pcie_cpl_dw2;
      
   block_pcie_s block_pcie;
   pcie_block_s pcie_block;
   
   reg [9:0]  length;
   reg [3:0]  state;
   reg [31:0] address;
   reg [31:0] upper_data;
   reg [7:0]  bar;
      
   assign axi_rx_out_hdr = axi_rx_out.tdata;
   assign axi_rx_out_w1  = axi_rx_out.tdata;

   always@(posedge sys.clk) begin
      if (sys.reset) begin
         pcie_hdr   <= 'b0;
         length     <= 'b0;
	 address    <= 'b0;
	 bar        <= 'b0;
	 length     <= 'b0;
	 upper_data <= 'b0;
	 state      <= IDLE_ST;
	 pcie_block <= 'b0;
	 axi_rx_in  <= 'b0;
	 axi_tx_in  <= 'b0;
	 pcie_cpl_qw0 <= 'b0;
	 pcie_cpl_dw2 <= 'b0;
	 	 	 	 
      end else begin // if (sys.reset)
	 case (state)
	   IDLE_ST: begin
	      axi_rx_in.tready   <= 1'b1;
	      axi_tx_in.tvalid   <= 1'b0;
	      pcie_block.vld     <= 1'b0;
	      
	      if (axi_rx_out.tvalid && axi_rx_in.tready) begin
		 pcie_hdr          <= axi_rx_out.tdata;
		 length            <= axi_rx_out_hdr.w0.len;
		 bar               <= axi_rx_out.tuser.bar;
		 if (axi_rx_out_hdr.w0.wdat) begin
		    if ((axi_rx_out.tuser.bar == COFFEE_BAR) ||         //Coef
			(axi_rx_out.tuser.bar == FREAK_BAR)    ) begin  //Ctrl
		       state <= WR_START_ST;
		       pcie_block.wr <= 1'b1;
		    end else begin
		       state <= CPL_US_SU_ST;
		    end
		 end else begin
		    if ((axi_rx_out.tuser.bar == COFFEE_BAR) ||         //Coef
			(axi_rx_out.tuser.bar == NOSE_BAR)   ||         //Pick
			(axi_rx_out.tuser.bar == RANDY_BAR)    ) begin  //Rnd
		       state         <= RD_SU_ST;
		       pcie_block.wr <= 1'b0;
		    end else begin
		       state <= CPL_US_SU_ST;
		    end
		 end
	      end
	   end // case: IDLE_ST

	   WR_START_ST: begin
	      if (axi_rx_out.tvalid && axi_rx_in.tready) begin
		 pcie_block.addr  <= axi_rx_out_w1.addr;
		 address          <= axi_rx_out_w1.addr;
		 pcie_block.data  <= axi_rx_out_w1.data;
		 axi_rx_in.tready <= 1'b1;

		 if (axi_rx_out_hdr.w0.dw4) begin
		    pcie_block.vld   <= 1'b0;
		    state            <= WR_W0_ST;
		 end else begin
		    pcie_block.vld   <= 1'b1;
		    if (length == 1) begin
		       state <= IDLE_ST;
		    end else begin
		       length <= length - 1;
		       state  <= WR_W0_ST;
		    end
		 end // else: !if(axi_rx_out_hdr.w0.dw4)
	      end // if (axi_rx_out.tvalid && axi_rx_in.tready)
	   end // case: WR_START_ST

	   WR_W0_ST: begin
	      if (axi_rx_out.tvalid && axi_rx_in.tready) begin
		 pcie_block.vld    <= 1'b1;
		 pcie_block.addr   <= address + 4;
		 address           <= address + 4;
		 pcie_block.data   <= axi_rx_out.tdata[31:0];
		 upper_data        <= axi_rx_out.tdata[63:32];
		 length            <= length - 1;
	      
		 axi_rx_in.tready  <= 1'b0;
		 if (length == 1) begin
		    state <= IDLE_ST;
		 end else begin
		    state <= WR_W1_ST;
		 end
	      end // if (axi_rx_out.tvalid && axi_rx_in.tready)
	   end // case: WR_W0_ST

	   WR_W1_ST: begin
	      pcie_block.vld    <= 1'b1;
	      pcie_block.addr   <= address + 4;
	      address           <= address + 4;
	      pcie_block.data   <= upper_data;
	      length            <= length - 1;
	      axi_rx_in.tready  <= 1'b1;
	      
	      if (length == 1) begin
		 state <= IDLE_ST;
	      end else begin
		 state <= WR_W0_ST;
	      end
	   end // case: WR_W1_ST

	   CPL_US_SU_ST: begin
	      pcie_cpl_qw0.w1.id   <= cpl_id;
	      pcie_cpl_qw0.w1.stat <= UNSUPP;
	      pcie_cpl_qw0.w1.bcnt <= 'h4;

	      pcie_cpl_qw0.w0.wdat <= 1'b0;
	      pcie_cpl_qw0.w0.dw4  <= 1'b0;
	      pcie_cpl_qw0.w0.typ  <= TYPE_CPL;
	      pcie_cpl_qw0.w0.len  <= 'b0;
	      
	      pcie_cpl_dw2.reqid    <= pcie_hdr.w1.reqid;
	      pcie_cpl_dw2.tag      <= pcie_hdr.w1.tag;
	      pcie_cpl_dw2.low_addr <= 'b0;

	      state <= CPL_US1_ST;
	   end // case: CPL_US_SU_ST
	   
	   CPL_US0_ST: begin
	      axi_tx_in.tvalid   <= 1'b1;
	      axi_tx_in.tkeep    <= 8'hff;
	      axi_tx_in.tuser    <= 'b0;
	      axi_tx_in.tlast    <= 1'b0;
	      
	      axi_tx_in.tdata    <= pcie_cpl_qw0;
	      state              <= CPL_US1_ST;
	   end
	   	   
	   CPL_US1_ST: begin
	      if (axi_tx_out.tready) begin
		 axi_tx_in.tvalid   <= 1'b1;
		 axi_tx_in.tkeep    <= 8'h0f;
		 axi_tx_in.tuser    <= 'b0;
		 axi_tx_in.tlast    <= 1'b1;
		 axi_tx_in.tdata    <= pcie_cpl_dw2;
		 state              <= CPL_US2_ST;
	      end
	   end

	   CPL_US2_ST: begin
	      if (axi_tx_out.tready) begin
		 axi_tx_in.tvalid <= 1'b0;
		 axi_rx_in.tready <= 1'b1;
	      	 state            <= IDLE_ST;
	      end
	   end

	   RD_SU_ST: begin
	      if (axi_rx_out.tvalid && axi_rx_in.tready) begin
		 axi_rx_in.tready   <= 1'b0;
		 pcie_block.addr <= axi_rx_out_w1.addr;
		 pcie_block.len  <= length;
		 pcie_block.vld  <= 1'b0;

		 pcie_cpl_qw0.w1.id   <= cpl_id;
		 pcie_cpl_qw0.w1.stat <= OK;
		 pcie_cpl_qw0.w1.bcnt <= 'h0;
		 
		 pcie_cpl_qw0.w0.wdat <= 1'b1;
		 pcie_cpl_qw0.w0.dw4  <= 1'b0;
		 pcie_cpl_qw0.w0.typ  <= TYPE_CPL;
		 pcie_cpl_qw0.w0.len  <= length;
		 
		 pcie_cpl_dw2.reqid    <= pcie_hdr.w1.reqid;
		 pcie_cpl_dw2.tag      <= pcie_hdr.w1.tag;
		 pcie_cpl_dw2.low_addr <= axi_rx_out_w1.addr[5:0];

		 state                 <= RD_CPL_START_ST;
		 
	      end // if (axi_rx_out.tvalid && axi_rx_in.tready)
	   end // case: RD_SU_ST
	   
	   RD_CPL_START_ST: begin
	      axi_tx_in.tdata  <= pcie_cpl_qw0;
	      axi_tx_in.tkeep  <= 8'hff;
	      axi_tx_in.tuser  <= 'b0;
	      axi_tx_in.tlast  <= 1'b0;
	      axi_tx_in.tvalid <= 1'b1;

	      state            <= RD_CPL0_ST;
	   end

	   RD_CPL0_ST: begin
	      if (axi_tx_out.tready == 1) begin
		 axi_tx_in.tvalid      <= 1'b0;
		 pcie_block.vld        <= 1'b1;
		 axi_tx_in.tdata[31:0] <= pcie_cpl_dw2;
		 state                 <= RD1_ST;
	      end
	   end
	   
	   RD0_ST: begin
	      axi_tx_in.tvalid <= 1'b0;
	      if (block_pcie.vld == 1'b1) begin
		 axi_tx_in.tdata[31:0] <= block_pcie.data;
		 length                <= length-1;
		 
		 if (length == 1) begin
		    axi_tx_in.tlast  <= 1'b1;
		    axi_tx_in.tkeep  <= 8'h0f;
		    axi_tx_in.tvalid <= 1'b1;
		    state            <= IDLE_ST;
		 end else begin
		    axi_tx_in.tvalid <= 1'b0;
		    state            <= RD1_ST;
		 end
	      end // if (block_pcie.vld == 1'b1)
	   end // case: RD0_ST
	   	   
	   RD1_ST: begin
	      if (block_pcie.vld == 1'b1) begin
		 axi_tx_in.tdata[63:32] <= block_pcie.data;
		 axi_tx_in.tvalid       <= 1'b1;
		 length                 <= length-1;
		 
		 if (length == 1) begin
		    axi_tx_in.tlast <= 1'b1;
		    state           <= IDLE_ST;
		 end else begin
		    state           <= RD0_ST;
		 end
	      end // if (block_pcie.vld == 1'b1)
	   end // case: RD1_ST
	   default: begin
	      axi_rx_in.tready   <= 1'b0;
	      axi_tx_in.tvalid   <= 1'b0;
	      pcie_block.vld     <= 1'b0;
	      state              <= IDLE_ST;
	   end
	 endcase // case (state)
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk)
    
//Read mux
   always@(posedge sys.clk) begin
      if (sys.reset) begin
         block_pcie     <= 'b0;
      end else begin
	 if (bar == COFFEE_BAR)  begin
	    block_pcie  <= coef_pcie;
	 end
	 else if (bar == NOSE_BAR)  begin
	    block_pcie  <= pick_pcie;
	 end
	 else if (bar == RANDY_BAR)  begin
	    block_pcie <= rnd_pcie;
	 end else begin
	    block_pcie  <= 'b0;
	 end
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk)
 
//Write Buffer
   always@(posedge sys.clk) begin
      if (sys.reset) begin
         pcie_coef     <= 'b0;
	 pcie_ctrl     <= 'b0;
      end else begin
	 if (bar == COFFEE_BAR)  begin
	    pcie_coef  <= pcie_block;
	 end else begin
	    pcie_coef.vld <= 1'b0;
	 end
	 
	 if (bar == FREAK_BAR)  begin
	    pcie_ctrl  <= pcie_block;
	 end else begin
	    pcie_ctrl.vld  <= 1'b0;
	 end
	 
	 if (bar == NOSE_BAR)  begin
	    pcie_pick  <= pcie_block;
	 end else begin
	    pcie_pick.vld  <= 1'b0;
	 end
	 
	 if (bar == RANDY_BAR)  begin
	    pcie_rnd  <= pcie_block;
	 end else begin
	    pcie_rnd.vld  <= 1'b0;
	 end
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk)
   
endmodule // axi_decoder

