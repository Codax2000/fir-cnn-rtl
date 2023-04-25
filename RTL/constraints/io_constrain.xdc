#set_property IOSTANDARD LVCMOS18 [get_ports {scan_in[0]}]
#set_property IOSTANDARD LVCMOS18 [get_ports clk_en_ff_0]
#set_property IOSTANDARD LVCMOS18 [get_ports {data_in[13]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {data_in[12]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {data_in[11]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {data_in[10]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {data_in[9]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {data_in[8]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {data_in[7]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {data_in[6]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {data_in[5]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {data_in[4]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {data_in[3]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {data_in[2]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {data_in[1]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {data_in[0]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {offset_in_0[13]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {offset_in_0[12]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {offset_in_0[11]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {offset_in_0[10]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {offset_in_0[9]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {offset_in_0[8]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {offset_in_0[7]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {offset_in_0[6]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {offset_in_0[5]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {offset_in_0[4]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {offset_in_0[3]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {offset_in_0[2]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {offset_in_0[1]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {offset_in_0[0]}]
#set_property IOSTANDARD LVCMOS18 [get_ports update]
set_property IOSTANDARD LVCMOS18 [get_ports rst]

#set_property PACKAGE_PIN AU23 [get_ports {scan_in[0]}]
#set_property IOSTANDARD LVCMOS18 [get_ports fire]
set_property IOSTANDARD LVCMOS18 [get_ports multi_loop_en]
#set_property IOSTANDARD LVCMOS18 [get_ports phi]
#set_property IOSTANDARD LVCMOS18 [get_ports phi_b]
#set_property PACKAGE_PIN J26 [get_ports phi_b]
#set_property PACKAGE_PIN B28 [get_ports phi]
set_property PACKAGE_PIN BB10 [get_ports multi_loop_en]
#set_property PACKAGE_PIN BA10 [get_ports fire]
set_property PACKAGE_PIN BB11 [get_ports rst]
#set_property PACKAGE_PIN AR22 [get_ports update]

set_property PACKAGE_PIN AR20 [get_ports clk_in_300]
set_property IOSTANDARD LVCMOS18 [get_ports clk_in_300]

#set_property PACKAGE_PIN AJ24 [get_ports {data_in[13]}]
#set_property PACKAGE_PIN AH24 [get_ports {data_in[12]}]
#set_property PACKAGE_PIN AK24 [get_ports {data_in[11]}]
#set_property PACKAGE_PIN AJ23 [get_ports {data_in[10]}]
#set_property PACKAGE_PIN AK26 [get_ports {data_in[9]}]
#set_property PACKAGE_PIN AJ26 [get_ports {data_in[8]}]
#set_property PACKAGE_PIN AL25 [get_ports {data_in[7]}]
#set_property PACKAGE_PIN AK25 [get_ports {data_in[6]}]
#set_property PACKAGE_PIN AM25 [get_ports {data_in[5]}]
#set_property PACKAGE_PIN AL24 [get_ports {data_in[4]}]
#set_property PACKAGE_PIN AK22 [get_ports {data_in[3]}]
#set_property PACKAGE_PIN AJ22 [get_ports {data_in[2]}]
#set_property PACKAGE_PIN AN25 [get_ports {data_in[1]}]
#set_property PACKAGE_PIN AN24 [get_ports {data_in[0]}]

#create_clock -period 4.000 -name VIRTUAL_clk_out2_design_1_clk_wiz_0_0 -waveform {0.000 2.000}
#create_clock -period 10.000 -name VIRTUAL_clk_out1_clk_wiz_0_1 -waveform {0.000 2.500}
#create_clock -period 9.999 -name VIRTUAL_clk_out1_design_1_clk_wiz_0_0 -waveform {0.000 4.999}
#set_input_delay -clock [get_clocks VIRTUAL_clk_out2_design_1_clk_wiz_0_0] -min -add_delay 1.000 [get_ports {data_in[*]}]
#set_input_delay -clock [get_clocks VIRTUAL_clk_out2_design_1_clk_wiz_0_0] -max -add_delay 1.500 [get_ports {data_in[*]}]
#set_input_delay -clock [get_clocks VIRTUAL_clk_out1_clk_wiz_0_1] -min -add_delay 2.000 [get_ports fire]
#set_input_delay -clock [get_clocks VIRTUAL_clk_out1_clk_wiz_0_1] -max -add_delay 3.000 [get_ports fire]
#set_input_delay -clock [get_clocks VIRTUAL_clk_out1_clk_wiz_0_1] -min -add_delay 2.000 [get_ports multi_loop_en]
#set_input_delay -clock [get_clocks VIRTUAL_clk_out1_clk_wiz_0_1] -max -add_delay 3.000 [get_ports multi_loop_en]
#set_input_delay -clock [get_clocks VIRTUAL_clk_out1_clk_wiz_0_1] -min -add_delay 2.000 [get_ports rst]
#set_input_delay -clock [get_clocks VIRTUAL_clk_out1_clk_wiz_0_1] -max -add_delay 3.000 [get_ports rst]
#set_input_delay -clock [get_clocks VIRTUAL_clk_out1_design_1_clk_wiz_0_0] -min -add_delay 2.000 [get_ports rst]
#set_input_delay -clock [get_clocks VIRTUAL_clk_out1_design_1_clk_wiz_0_0] -max -add_delay 3.000 [get_ports rst]
#set_input_delay -clock [get_clocks VIRTUAL_clk_out2_design_1_clk_wiz_0_0] -min -add_delay 1.000 [get_ports rst]
#set_input_delay -clock [get_clocks VIRTUAL_clk_out2_design_1_clk_wiz_0_0] -max -add_delay 1.500 [get_ports rst]
#set_output_delay -clock [get_clocks VIRTUAL_clk_out1_clk_wiz_0_1] -min -add_delay 0.000 [get_ports {scan_in[0]}]
#set_output_delay -clock [get_clocks VIRTUAL_clk_out1_clk_wiz_0_1] -max -add_delay 1.100 [get_ports {scan_in[0]}]
#set_output_delay -clock [get_clocks VIRTUAL_clk_out1_clk_wiz_0_1] -min -add_delay 0.000 [get_ports update]
#set_output_delay -clock [get_clocks VIRTUAL_clk_out1_clk_wiz_0_1] -max -add_delay 1.100 [get_ports update]


#set_property DRIVE 12 [get_ports phi]
#set_property DRIVE 12 [get_ports phi_b]
#set_property DRIVE 12 [get_ports update]
#set_property DRIVE 12 [get_ports {scan_in[0]}]

#set_property PACKAGE_PIN L17 [get_ports phi_b_test]
#set_property PACKAGE_PIN M17 [get_ports phi_test]
#set_property IOSTANDARD LVCMOS18 [get_ports phi_b_test]
#set_property IOSTANDARD LVCMOS18 [get_ports phi_test]
#set_property SLEW SLOW [get_ports phi]
#set_property OFFCHIP_TERM NONE [get_ports phi_b_test]
#set_property OFFCHIP_TERM NONE [get_ports phi_test]
#set_property SLEW SLOW [get_ports phi_b]




set_property IOSTANDARD LVCMOS18 [get_ports clk_data]



set_property IOSTANDARD DIFF_SSTL12 [get_ports default_sysclk_c0_300mhz_clk_p]

set_property PACKAGE_PIN D1 [get_ports sysref_in_0_diff_n]
set_property PACKAGE_PIN D2 [get_ports sysref_in_0_diff_p]
set_property PACKAGE_PIN D13 [get_ports tvalid_0]
set_property IOSTANDARD LVCMOS18 [get_ports tvalid_0]
set_property PACKAGE_PIN AU4 [get_ports vin00_0_v_n]
set_property PACKAGE_PIN AU5 [get_ports vin00_0_v_p]
set_property PACKAGE_PIN A19 [get_ports {external_signal_bus_0[3]}]
set_property PACKAGE_PIN A20 [get_ports {external_signal_bus_0[2]}]
set_property PACKAGE_PIN A22 [get_ports {external_signal_bus_0[1]}]
set_property PACKAGE_PIN A23 [get_ports {external_signal_bus_0[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {external_signal_bus_0[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {external_signal_bus_0[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {external_signal_bus_0[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {external_signal_bus_0[0]}]
set_property PACKAGE_PIN AP16 [get_ports {state_reg_0[5]}]
set_property PACKAGE_PIN D14 [get_ports {state_reg_0[4]}]
set_property PACKAGE_PIN E24 [get_ports {state_reg_0[3]}]
set_property PACKAGE_PIN AP14 [get_ports {state_reg_0[2]}]
set_property PACKAGE_PIN D12 [get_ports {state_reg_0[1]}]
set_property PACKAGE_PIN G26 [get_ports {state_reg_0[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {state_reg_0[5]}]
set_property IOSTANDARD LVCMOS18 [get_ports {state_reg_0[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {state_reg_0[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {state_reg_0[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {state_reg_0[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {state_reg_0[0]}]
set_property PACKAGE_PIN AY4 [get_ports adc1_clk_0_clk_n]
set_property PACKAGE_PIN AW4 [get_ports adc1_clk_0_clk_p]

#set_property OFFCHIP_TERM NONE [get_ports phi]
#set_property OFFCHIP_TERM NONE [get_ports phi_b]
#set_property OFFCHIP_TERM NONE [get_ports update]
#set_property OFFCHIP_TERM NONE [get_ports scan_in[0]]

set_property PACKAGE_PIN BA10 [get_ports fire_1]
set_property IOSTANDARD LVCMOS18 [get_ports fire_1]
set_property PACKAGE_PIN AN24 [get_ports phi_E]
set_property IOSTANDARD LVCMOS18 [get_ports phi_E]
set_property PACKAGE_PIN AU22 [get_ports phi_G]
set_property IOSTANDARD LVCMOS18 [get_ports phi_G]
set_property PACKAGE_PIN AR22 [get_ports phi_W]
set_property IOSTANDARD LVCMOS18 [get_ports phi_W]
set_property PACKAGE_PIN AN25 [get_ports phi_bar_E]
set_property IOSTANDARD LVCMOS18 [get_ports phi_bar_E]
set_property PACKAGE_PIN AT22 [get_ports phi_bar_G]
set_property IOSTANDARD LVCMOS18 [get_ports phi_bar_G]
set_property PACKAGE_PIN AP22 [get_ports phi_bar_W]
set_property PACKAGE_PIN A32 [get_ports update_1]
set_property IOSTANDARD LVCMOS18 [get_ports update_1]
set_property PACKAGE_PIN C31 [get_ports update_2]
set_property IOSTANDARD LVCMOS18 [get_ports update_2]
set_property PACKAGE_PIN AV23 [get_ports update_3]
set_property IOSTANDARD LVCMOS18 [get_ports update_3]
set_property PACKAGE_PIN AR25 [get_ports update_4]
set_property IOSTANDARD LVCMOS18 [get_ports update_4]
set_property PACKAGE_PIN AL24 [get_ports update_5]
set_property IOSTANDARD LVCMOS18 [get_ports update_5]
set_property PACKAGE_PIN AJ22 [get_ports update_6]
set_property IOSTANDARD LVCMOS18 [get_ports update_6]
set_property PACKAGE_PIN AM23 [get_ports update_G]
set_property IOSTANDARD LVCMOS18 [get_ports update_G]
set_property PACKAGE_PIN B32 [get_ports {scan_in_1[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {scan_in_1[0]}]
set_property PACKAGE_PIN C30 [get_ports {scan_in_2[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {scan_in_2[0]}]
set_property PACKAGE_PIN A28 [get_ports {scan_in_3[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {scan_in_3[0]}]
set_property PACKAGE_PIN AN26 [get_ports {scan_in_4[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {scan_in_4[0]}]
set_property PACKAGE_PIN AM25 [get_ports {scan_in_5[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {scan_in_5[0]}]
set_property PACKAGE_PIN AK22 [get_ports {scan_in_6[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {scan_in_6[0]}]
set_property PACKAGE_PIN AP23 [get_ports {scan_in_G[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {scan_in_G[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports phi_bar_W]



set_property PACKAGE_PIN AY10 [get_ports sw1_1]
set_property PACKAGE_PIN AY11 [get_ports sw2_1]
set_property PACKAGE_PIN BA9 [get_ports sw3_1]
set_property PACKAGE_PIN AY9 [get_ports sw4_1]
set_property PACKAGE_PIN BB9 [get_ports sw5_1]
set_property IOSTANDARD LVCMOS18 [get_ports sw1_1]
set_property IOSTANDARD LVCMOS18 [get_ports sw2_1]
set_property IOSTANDARD LVCMOS18 [get_ports sw3_1]
set_property IOSTANDARD LVCMOS18 [get_ports sw4_1]
set_property IOSTANDARD LVCMOS18 [get_ports sw5_1]

set_property IOSTANDARD LVCMOS18 [get_ports {state_reg_0[6]}]
set_property PACKAGE_PIN AN14 [get_ports {state_reg_0[6]}]

set_property PACKAGE_PIN AU16 [get_ports tvalid_1]
set_property IOSTANDARD LVCMOS18 [get_ports tvalid_1]
set_property PACKAGE_PIN AU4 [get_ports vin00_v_n]
