// Module to sum up the results of the coef memory multiplications

module sum
  (sys,	  
   subtotal_q,

   full_sum   
   );

`include "params.svh"
`include "structs.svh"
      
   input sys_s           sys;
   input [MAX_CMEM_DATA:0] subtotal_q [0:MAX_CMEM];
   
   output reg signed [23:0]  full_sum;

   reg signed [23:0]  sum_q [0:((MAX_CMEM+1)/2) -1][0:MAX_CMEM_SEL-1];
   
   integer 	      i;
   integer 	      j;
   integer 	      nperlevel;
   integer 	      was_odd;
   
   always@(posedge sys.clk or posedge sys.reset) begin
      if (sys.reset) begin
	 for (j=0;j<=MAX_CMEM_SEL;j=j+1) begin
	    nperlevel = (MAX_CMEM+1) >> (j+1);
	 
	    for (i=0;i<nperlevel;i=i+1) begin 
	       sum_q[i][j] <= 'b0;
	       $display("Initing %d %d",i,j);
	    end
	 end
      end else begin
	 j=0;  //first level first
	 
	 nperlevel = (MAX_CMEM+1) >> (j+1);
	 
	 for (i=0;i<nperlevel;i=i+1) begin
	    sum_q[i][0] <= $signed(subtotal_q[2*i])        +
	                   $signed(subtotal_q[(2*i) + 1]);  //MAX_CMEM is even
	 end
	 for (j=1;j<=MAX_CMEM_SEL;j=j+1) begin
	    nperlevel = (MAX_CMEM+1) >> (j+1);
	    was_odd   = ((MAX_CMEM+1) >> j) & 1'b1;
	    	 
	    for (i=0;i<nperlevel;i=i+1) begin       
	       if ((i == (nperlevel-1)) && was_odd) begin  //check if extra
		  sum_q[i][j] <= sum_q[2*i][j-1] + 
				 sum_q[(2*i)+1][j-1] + 
				 sum_q[(2*i)+2][j-1];
	       end else begin
		  sum_q[i][j] <= sum_q[2*i][j-1] + 
				 sum_q[(2*i)+1][j-1];
	       end
	    end
	 end
      end // else: !if(sys.rst)
   end // always@ (posedge sys.clk or posedge sys.rst)

   always@(posedge sys.clk or posedge sys.reset) begin
      if (sys.reset) begin
	 full_sum <= 'b0;
      end else begin
	 full_sum <= sum_q[0][MAX_CMEM_SEL-1];
      end
   end
   
	 
endmodule // sum

   
 
 
