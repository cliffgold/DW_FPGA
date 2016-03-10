## DW_FPGA
# Emulate Quantum Annealing

There is a Quantum Computing machine from DWave which can solve a certain class of problems.  This is meant to emulate that process.

The way I envision it, the FPGA would be on a card plugged into a PC.  The Xilinx 700-series boards seem to be a good approach.  The card could solve problems of the type that DWave solves, only without the Quantum magic.

In ordered to use this data base, you need Vivado (Web edition is fine for a start.  It's free), and utilities like make.  You need to manually set the path for the Xilinx tools (something like Xilinx/Vivado/2015.4/bin), and XILINX_VIVADO to Xilinx/vivado/2015.4.

Type "make" in the DW_FPGA directory, and you're off and running.  It is set up for project flow, so use the gui if you're more comfortable with that.
