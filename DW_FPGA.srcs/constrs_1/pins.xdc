set DW_PERIOD 10
set DW_HALF   [expr $DW_PERIOD / 2.0]
set DW_IN_MAX 1.0
set DW_IN_MIN -1.0
set DW_OUT_MAX 1.0
set DW_OUT_MIN -1.0

set_input_delay -clock clk_input -max $DW_IN_MAX [get_ports bus_pcie*]
set_input_delay -clock clk_input -min $DW_IN_MIN [get_ports bus_pcie*]
set_input_delay -clock clk_input -max $DW_IN_MAX [get_ports rst_in]
set_input_delay -clock clk_input -min $DW_IN_MIN [get_ports rst_in]

set_output_delay -clock clkin_out -max $DW_OUT_MAX [get_ports pcie_bus*]
set_output_delay -clock clkin_out -min $DW_OUT_MIN [get_ports pcie_bus*]

set_property IOSTANDARD LVCMOS15 [get_ports bus_pcie*]
set_property IOSTANDARD LVCMOS15 [get_ports pcie_bus*]
set_property IOSTANDARD LVCMOS15 [get_ports clk_input]
set_property IOSTANDARD LVCMOS15 [get_ports clk_output]
set_property IOSTANDARD LVCMOS15 [get_ports rst_in]

set_property DRIVE 4 [get_ports pcie_bus*]
set_property DRIVE 4 [get_ports clk_output]

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


