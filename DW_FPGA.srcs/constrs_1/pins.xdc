set DW_PERIOD [get_property CLKIN1_PERIOD [get_cells {clk_gen_0/clk_wiz_0_0/inst/mmcm_adv_inst}]]
set DW_HALF   [expr $DW_PERIOD / 2.0]
set DW_IN_MAX 2

set_property IOSTANDARD LVCMOS15 [get_ports bus_pcie*]
set_property IOSTANDARD LVCMOS15 [get_ports pcie_bus*]
set_property IOSTANDARD LVCMOS15 [get_ports clk_input]
set_property IOSTANDARD LVCMOS15 [get_ports rst_in]

set_property DRIVE 4 [get_ports pcie_bus*]

set_property INTERNAL_VREF 0.75 [get_iobanks 12]
set_property INTERNAL_VREF 0.75 [get_iobanks 13]
set_property INTERNAL_VREF 0.75 [get_iobanks 14]
set_property INTERNAL_VREF 0.75 [get_iobanks 15]
set_property INTERNAL_VREF 0.75 [get_iobanks 16]
set_property INTERNAL_VREF 0.75 [get_iobanks 32]
set_property INTERNAL_VREF 0.75 [get_iobanks 33]
set_property INTERNAL_VREF 0.75 [get_iobanks 34]

set_property CONFIG_VOLTAGE 1.5 [current_design]
set_property CFGBVS GND [current_design]

create_clock -period $DW_PERIOD -waveform "0 $DW_HALF" [get_ports clk_input] 

#These constraints are pretty loose
set_input_delay -clock clk_input -max $DW_IN_MAX [get_ports bus_pcie*]
set_input_delay -clock clk_input -min 0.000      [get_ports bus_pcie*]
set_input_delay -clock clk_input -max $DW_IN_MAX [get_ports rst_in]
set_input_delay -clock clk_input -min 0.000      [get_ports rst_in]

create_generated_clock -source [get_pins clk_gen_0/clk_bufg_0/O] -divide_by 1 [get_ports clk_output]
set_output_delay -clock clk_output -max 1.000 [get_ports pcie_bus*]
set_output_delay -clock clk_output -min 0.000 [get_ports pcie_bus*]

