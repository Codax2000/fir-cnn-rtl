`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/02/2023 08:24:52 PM
// Design Name: 
// Module Name: fc_node
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


module fc_node #(
    parameter WORD_SIZE=16,
    parameter INPUT_LAYER_HEIGHT=4) (
    input logic clk_i,
    input logic reset_i,
    input logic [INPUT_LAYER_HEIGHT - 1:0][WORD_SIZE - 1:0] data_i,
    input [WORD_SIZE - 1:0] bias_i,
    input logic [INPUT_LAYER_HEIGHT - 1:0][WORD_SIZE - 1:0] weights_i,
    output [WORD_SIZE - 1:0] data_o
    );
endmodule
