// Module to sum up the results of the coef memory multiplications

module sum
  (sys,	  
   coef_sum,

   sum_pick 
   );

`include "params.svh"
`include "structs.svh"
      
   input sys_s      sys;
   input 	     coef_sum_s coef_sum;
   
   output 	     sum_pick_s sum_pick;

   reg signed [23:0] sum_q [0:((NCMEMS)/2) -1][0:CMEM_SEL_W];
   reg [RUN_W:0]  run;
    
   integer 	      i;
   integer 	      j;
   integer 	      nperlevel;
   integer 	      was_odd;
   
//TBD Double-check the number of j's

   always@(posedge sys.clk) begin
      if (sys.reset) begin
	 run    <= 'b0;
	 for (j=0;j<=CMEM_SEL_W;j=j+1) begin
	    nperlevel = (NCMEMS) >> (j+1);
	    for (i=0;i<nperlevel;i=i+1) begin 
	       sum_q[i][j] <= 'b0;
	    end
	 end
      end else begin
	 j=0;  //first level first
	 nperlevel = (NCMEMS) >> (j+1);
	 
	 run <= coef_sum.run;
	 
	 for (i=0;i<nperlevel;i=i+1) begin
	    sum_q[i][0] <= $signed(coef_sum.subtotal[2*i])      +
	                   $signed(coef_sum.subtotal[(2*i) + 1]);  //NCMEMS-1 is even
	 end
	 for (j=1;j<=CMEM_SEL_W;j=j+1) begin
	    nperlevel = (NCMEMS) >> (j+1);
	    was_odd   = ((NCMEMS) >> j) & 1'b1;
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
   end // always@ (posedge sys.clk )

   always@(posedge sys.clk) begin
      if (sys.reset) begin
	 sum_pick.full_sum <= 'b0;
	 sum_pick.run      <= 'b0;
      end else begin
	 sum_pick.full_sum <= sum_q[0][CMEM_SEL_W];
	 sum_pick.run      <= (NRUNS+run - SUM_RUN)% NRUNS;	 
      end
   end
   
	 
endmodule // sum

   
 
 
