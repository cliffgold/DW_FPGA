// Module to control one of 16 runs
`include "timescale.svh"

module ctrl_onerun
  (sys,
   ram_whoami,
   ram_we,  
   ram_addr,
   ram_data,
   start,   
   stop,    
   step,

   ctrl_word,
   ctrl_busy
   );

`include "params.svh"
`include "structs.svh"
      
   localparam IDLE    = 2'b00;
   localparam LOADING = 2'b01;
   localparam RUNNING = 2'b10;
   
   input sys_s        sys;

   input [RUN_W:0]    ram_whoami;
   input              ram_we;
   input ctrl_addr_s  ram_addr;
   input [31:0]       ram_data;

   input              start;
   input              stop;
   input 	      step;
   
   output ctrl_word_s ctrl_word;
   output reg         ctrl_busy;

   reg [CTRL_MEM_ADDR_W:0] ctrl_addr;
   reg [CTRL_MEM_ADDR_W:0] addr;
   
   reg [96:0]         ram_data_out;
   reg                ram_we0;
   reg 		      ram_we1;
   reg 		      ram_we2;
   
   reg [1:0] 	      state;
         
   always@(posedge sys.clk) begin
      if (sys.reset) begin
	 state     <= IDLE;
	 ctrl_addr <= 'h0;
	 ctrl_word <= 'b0;
	 ctrl_busy <= 'b0;
      end else begin
	 if (stop) begin
	    state <= IDLE;
	    ctrl_addr <= 'b0;
	    ctrl_busy <= 'b0;
	 end 
	 else if (step) begin
	    case (state)
	      IDLE: begin
		 if (start) begin
		    state     <= LOADING;
		 end else begin
		    state     <= IDLE;
		 end // else: !if(start)
	      end // case: state...
	      LOADING: begin
		 ctrl_busy  <= 1'b1;
		 ctrl_word  <= ram_data_out[CTRL_WORD_S_W:0];
		 ctrl_addr  <= ctrl_addr+1;
		 state      <= RUNNING;
	      end // case: LOADING
	      RUNNING: begin
		 ctrl_word.count <= ctrl_word.count - 'b1;
		 if (ctrl_word.count == 'b1) begin
		    if (ctrl_word.next) begin
		       state     <= LOADING;
		    end else begin
		       state     <= IDLE;
		       ctrl_addr <= 'h0;
		       ctrl_busy <= 'b0;
		    end
		 end else begin // if (count == 'b1)
		 end // else: !if(count == 'b1)
	      end // case: RUNNING
	      default: begin
		 state     <= IDLE;
		 ctrl_addr <= 'h0;
		 ctrl_busy <= 'b0;
	      end
	    endcase // case (state)
	 end // if (step)
      end // else: !if(sys.reset)
   end // always@ (posedge sys.clk)
   
   always@(*) begin
      if ((ram_we == 1) && (ram_whoami == ram_addr.run)) begin
	 addr = ram_addr.addr;
	 
	 case (ram_addr.part)
	   0: begin
	      ram_we0 = 1'b1;
	      ram_we1 = 1'b0;
	      ram_we2 = 1'b0;
	   end
	   1: begin
	      ram_we0 = 1'b0;
	      ram_we1 = 1'b1;
	      ram_we2 = 1'b0;
	   end
	   2: begin
	      ram_we0 = 1'b0;
	      ram_we1 = 1'b0;
	      ram_we2 = 1'b1;
	   end
	   default: begin
	      ram_we0 = 1'b0;
	      ram_we1 = 1'b0;
	      ram_we2 = 1'b0;
	   end
	 endcase // case (ram_addr.part)
      end else begin
	 addr = ctrl_addr;
	 ram_we0 = 1'b0;
	 ram_we1 = 1'b0;
	 ram_we2 = 1'b0;
      end
   end // always@ (*)

   ctrl0_mem ctrl0_mem_0
     (
      .ena(sys.reset_n),
      .addra(addr),
      .dina(ram_data[31:0]),
      .douta(ram_data_out[31:0]),
      .wea(ram_we0),
      .clka(sys.clk)
      );

   ctrl0_mem ctrl0_mem_1
     (
      .ena(sys.reset_n),
      .addra(addr),
      .dina(ram_data[31:0]),
      .douta(ram_data_out[63:32]),
      .wea(ram_we1),
      .clka(sys.clk)
      );

   ctrl0_mem ctrl0_mem_2
     (
      .ena(sys.reset_n),
      .addra(addr),
      .dina(ram_data[31:0]),
      .douta(ram_data_out[95:64]),
      .wea(ram_we2),
      .clka(sys.clk)
      );

endmodule // ctrl_ram



   
