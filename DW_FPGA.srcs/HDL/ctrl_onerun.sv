// Module to control one of 16 runs

module ctrl_onerun
  (sys,
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
   input              ram_we;
   input [9:0]        ram_addr;
   input ctrl_word_s  ram_data;
   input              start;
   input              stop;
   input 	      step;
   
   output ctrl_word_s ctrl_word;
   output reg         ctrl_busy;

   reg [9:0] 	      ctrl_addr;
   reg [9:0] 	      addr;
   
   ctrl_word_s        ram_data_out;

   reg [1:0] 	      state;
         
   always@(posedge sys.clk or posedge sys.reset) begin
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
		    ctrl_addr <= 'h0;
		    ctrl_busy <= 'b0;
		 end // else: !if(start)
	      end // case: state...
	      LOADING: begin
		 ctrl_busy   <= 1'b0;
		 ctrl_word   <= ram_data_out;
		 if (ram_data_out.count == 'b0) begin
		    if (ram_data_out.done) begin
		       state     <= IDLE;
		       ctrl_addr <= 'b0;
		    end else begin
		       state     <= LOADING;
		       ctrl_addr <= ctrl_addr + 'b1;
		    end
		 end else begin
		    state     <= RUNNING;
		 end // else: !if(ctrl_word.count == 'b0)
	      end // case: LOADING
	      RUNNING: begin
		 if (ctrl_word.count == 'b1) begin
		    if (ram_data_out.done) begin
		       state     <= IDLE;
		    end else begin
		       state     <= LOADING;
		       ctrl_addr <= ctrl_addr + 'b1;
		    end
		 end else begin // if (count == 'b1)
		    ctrl_word.count <= ctrl_word.count - 'b1;
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
   end // always@ (posedge sys.clk or posedge sys.reset)
   
   always@(*) begin
      if (ram_we) begin
	 addr = ram_addr;
      end else begin
	 addr = ctrl_addr;
      end
   end // always@ (*)
   
   blk_mem_gen_1 ctrl_mem_0
     (
      .addra(addr),
      .dina(ram_data),
      .douta(ram_data_out),
      .ena(~ram_we),
      .wea(ram_we),
      .clka(sys.clk)
      );

endmodule // ctrl_ram



   
