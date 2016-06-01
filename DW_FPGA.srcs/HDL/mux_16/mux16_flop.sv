//
///////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2011-2012, Xilinx, Inc.
// This file contains confidential and proprietary information of Xilinx, Inc. and is
// protected under U.S. and international copyright and other intellectual property laws.
///////////////////////////////////////////////////////////////////////////////////////////
//
// Disclaimer:
// This disclaimer is not a license and does not grant any rights to the materials
// distributed herewith. Except as otherwise provided in a valid license issued to
// you by Xilinx, and to the maximum extent permitted by applicable law: (1) THESE
// MATERIALS ARE MADE AVAILABLE "AS IS" AND WITH ALL FAULTS, AND XILINX HEREBY
// DISCLAIMS ALL WARRANTIES AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY,
// INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-INFRINGEMENT,
// OR FITNESS FOR ANY PARTICULAR PURPOSE; and (2) Xilinx shall not be liable
// (whether in contract or tort, including negligence, or under any other theory
// of liability) for any loss or damage of any kind or nature related to, arising
// under or in connection with these materials, including for any direct, or any
// indirect, special, incidental, or consequential loss or damage (including loss
// of data, profits, goodwill, or any type of loss or damage suffered as a result
// of any action brought by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-safe, or for use in any
// application requiring fail-safe performance, such as life-support or safety
// devices or systems, Class III medical devices, nuclear facilities, applications
// related to the deployment of airbags, or any other applications that could lead
// to death, personal injury, or severe property or environmental damage
// (individually and collectively, "Critical Applications"). Customer assumes the
// sole risk and liability of any use of Xilinx products in Critical Applications,
// subject only to applicable laws and regulations governing limitations on product
// liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES.
//
///////////////////////////////////////////////////////////////////////////////////////////
//
// Traditional 16:1 Multiplexer in one Slice. 
//
// Suitable for Spartan-6, Virtex-6 and 7-Series devices.
//
// This is an example of a multiplexer implemented using the techniques described 
// in XAPP522.
//
// 25th May 2012.
//
///////////////////////////////////////////////////////////////////////////////////////////
//
// Format of this file.
//
// The module defines the implementation of the logic using Xilinx primitives.
// These ensure predictable synthesis results and maximise the density of the 
// implementation. The Unisim Library is used to define Xilinx primitives. It is also 
// used during simulation. 
// The source can be viewed at %XILINX%\verilog\src\unisims\
// 
///////////////////////////////////////////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////////////////
//
// Modified by CG to add a flop at the end, as described
//  in the readme file included with the reference design
//

`include "timescale.svh"

module mux16_flop (
 input 	      clk,
 input        reset,
 input [15:0] data_in,
 input [3:0]  sel,
 output       data_out_q);

//
///////////////////////////////////////////////////////////////////////////////////////////
//
// Wires used in standard_mux16
//
///////////////////////////////////////////////////////////////////////////////////////////
//

wire  [3:0] data_selection;
wire  [1:0] combiner;
   wire     data_out;
   

//
///////////////////////////////////////////////////////////////////////////////////////////
//
// Start of standard_mux16 circuit description
//
///////////////////////////////////////////////////////////////////////////////////////////
//	

LUT6 #(
        .INIT    (64'hFF00F0F0CCCCAAAA))
selection0_lut( 
        .I0     (data_in[0]),
        .I1     (data_in[1]),
        .I2     (data_in[2]),
        .I3     (data_in[3]),
        .I4     (sel[0]),
        .I5     (sel[1]),
        .O      (data_selection[0])); 


LUT6 #(
        .INIT    (64'hFF00F0F0CCCCAAAA))
selection1_lut( 
        .I0     (data_in[4]),
        .I1     (data_in[5]),
        .I2     (data_in[6]),
        .I3     (data_in[7]),
        .I4     (sel[0]),
        .I5     (sel[1]),
        .O      (data_selection[1])); 


MUXF7 combiner0_muxf7 ( 
       .I0      (data_selection[0]),
       .I1      (data_selection[1]),                     
       .S       (sel[2]),
       .O       (combiner[0])) ;


LUT6 #(
        .INIT    (64'hFF00F0F0CCCCAAAA))
selection2_lut( 
        .I0     (data_in[8]),
        .I1     (data_in[9]),
        .I2     (data_in[10]),
        .I3     (data_in[11]),
        .I4     (sel[0]),
        .I5     (sel[1]),
        .O      (data_selection[2])); 


LUT6 #(
        .INIT    (64'hFF00F0F0CCCCAAAA))
selection3_lut( 
        .I0     (data_in[12]),
        .I1     (data_in[13]),
        .I2     (data_in[14]),
        .I3     (data_in[15]),
        .I4     (sel[0]),
        .I5     (sel[1]),
        .O      (data_selection[3])); 


MUXF7 combiner1_muxf7 ( 
       .I0      (data_selection[2]),
       .I1      (data_selection[3]),                     
       .S       (sel[2]),
       .O       (combiner[1])) ;


MUXF8 combiner_muxf8 ( 
       .I0      (combiner[0]),
       .I1      (combiner[1]),                     
       .S       (sel[3]),
       .O       (data_out)) ;

   // Added by CG per the readme file from Xilinx

// FDCE: Single Data Rate D Flip-Flop with Asynchronous Clear and
// Clock Enable (posedge clk).
// 7 Series
// Xilinx HDL Libraries Guide, version 2015.4
   FDRE #
     (.INIT(1'b0)) // Initial value of register (1'b0 or 1'b1)
   FDRE_inst 
     (
      .Q(data_out_q), // 1-bit Data output
      .C(clk),        // 1-bit Clock input
      .CE(1'b1),      // 1-bit Clock enable input
      .R(reset),      // 1-bit synchronous clear input
      .D(data_out)    // 1-bit Data input
      );
// End of FDCE_inst instantiation
   
endmodule

///////////////////////////////////////////////////////////////////////////////////////////
//
// END OF FILE standard_mux16.v
//
///////////////////////////////////////////////////////////////////////////////////////////


