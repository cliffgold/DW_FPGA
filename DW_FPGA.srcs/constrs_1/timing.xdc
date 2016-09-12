# Clock anbd timing constraints

create_clock -name sys_clk -period 10 [get_ports pclk_p]

set_false_path -from [get_ports prst_n]
