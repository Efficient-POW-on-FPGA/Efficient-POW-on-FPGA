set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports sys_clk];

set_property IOSTANDARD LVCMOS33 [get_ports rx_pin]
set_property IOSTANDARD LVCMOS33 [get_ports tx_pin]

set_property PACKAGE_PIN A9 [get_ports rx_pin]
set_property PACKAGE_PIN D10 [get_ports tx_pin]

#set_property CONFIG_VOLTAGE 1.8 [current_design]
#set_property CFGBVS GND [current_design]
