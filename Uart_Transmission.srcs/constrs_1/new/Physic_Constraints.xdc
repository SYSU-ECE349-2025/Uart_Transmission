set_property PACKAGE_PIN C25 [get_ports sys_clk]
set_property IOSTANDARD LVCMOS33 [get_ports sys_clk]
# 板级时钟名称，周期，sys_clk40ns50占空比，*相移%0
create_clock -period 40.000 -name sys_clk -waveform {0.000 20.000} [get_ports sys_clk]
set_property PACKAGE_PIN B24 [get_ports rx]
set_property IOSTANDARD LVCMOS33 [get_ports rx]
set_property PACKAGE_PIN B27 [get_ports tx]
set_property IOSTANDARD LVCMOS33 [get_ports tx]