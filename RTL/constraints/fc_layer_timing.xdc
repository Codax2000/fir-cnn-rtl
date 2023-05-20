create_clock -period 40.000 -name clk -waveform {0.000 20.000} [get_ports clk_i]

set_input_delay -clock [get_clocks clk] -min 0.000  [get_ports -filter { NAME =~  "*data*" && DIRECTION == "IN" }]
set_input_delay -clock [get_clocks clk] -max 20.000 [get_ports -filter { NAME =~  "*data*" && DIRECTION == "IN" }]

set_output_delay -clock [get_clocks clk] -max 20.000 [get_ports -filter { NAME =~  "*data*" && DIRECTION == "OUT" }]
set_output_delay -clock [get_clocks clk] -min 0.000  [get_ports -filter { NAME =~  "*data*" && DIRECTION == "OUT" }]

set_input_delay -clock [get_clocks clk] -max 20.000 [get_ports {reset_i}]
set_input_delay -clock [get_clocks clk] -min  0.000 [get_ports {reset_i}]

set_input_delay -clock [get_clocks clk] -min  0.000 [get_ports {yumi_i valid_i}]
set_input_delay -clock [get_clocks clk] -max 20.000 [get_ports {yumi_i valid_i}]

set_output_delay -clock [get_clocks clk] -max 20.000 [get_ports {valid_o ready_o}]
set_output_delay -clock [get_clocks clk] -min 0.000  [get_ports {valid_o ready_o}]