`timescale 1ns / 1ps
`define VIVADO
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/22/2023 08:44:07 PM
// Design Name: 
// Module Name: zyNet_wrapper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module zyNet_wrapper# (
    parameter WORD_SIZE = 16,
    parameter OUTPUT_SIZE = 10
) (
    // top level signals
    input wire clk_i,
    input wire reset_i,
    input wire start_i,
    output wire conv_ready_o,
    
    // helpful handshake in
    input wire [WORD_SIZE-1:0] data_i,
    input wire valid_i,
    output wire ready_o,

    // helpful handshake out
    output wire [OUTPUT_SIZE*WORD_SIZE-1:0] data_o,
    output wire valid_o,
    input wire yumi_i
    );
    
    zyNet cnn (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .start_i(start_i),
        .conv_ready_o(conv_ready_o),
        .data_i(data_i),
        .valid_i(valid_i),
        .ready_o(ready_o),
        .data_o(data_o),
        .valid_o(valid_o),
        .yumi_i(yumi_i)
    );
    
endmodule
