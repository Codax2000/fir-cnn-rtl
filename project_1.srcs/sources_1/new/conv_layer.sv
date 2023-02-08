`timescale 1ns / 1ps

/**
Alex Knowlton
2/6/2023

1 layer of convolutional layer for neural network using ReLU activation function
Multiple parameters allow this module to be highly customizeable
NOTE: Kernel width and data width must be the same, so we are assuming a 1-wide output layer
Also, data height must be greater than or equal to kernel height or the computation will fail
*/



module conv_layer #(
    parameter WORD_SIZE=16,
    parameter KERNEL_HEIGHT=3,
    parameter KERNEL_WIDTH=4,
    parameter DATA_HEIGHT=5)(
    input logic clk_i,
    input logic reset_i,
    input logic [KERNEL_HEIGHT - 1:0][KERNEL_WIDTH - 1:0][WORD_SIZE - 1:0] kernel_i,
    input logic [DATA_HEIGHT - 1:0][KERNEL_WIDTH - 1:0][WORD_SIZE - 1:0] data_i,
    input logic [DATA_HEIGHT - KERNEL_HEIGHT + 1:0][WORD_SIZE - 1:0] bias_i, // one bias for each piece of output
    output logic [DATA_HEIGHT - KERNEL_HEIGHT + 1:0][WORD_SIZE - 1:0] data_o);
    
    // just generate a bunch of convolutional nodes, one for each output value
    genvar i;
    generate
        for (i = 0; i < DATA_HEIGHT - KERNEL_HEIGHT + 1; i = i + 1) begin
            conv_node #(
                .KERNEL_HEIGHT(KERNEL_HEIGHT),
                .KERNEL_WIDTH(KERNEL_WIDTH),
                .WORD_SIZE(WORD_SIZE)
            ) node (
                .clk_i,
                .reset_i,
                .kernel_i,
                .data_i(data_i[i + KERNEL_HEIGHT - 1:i]),
                .bias_i(bias_i[i]),
                .data_o(data_o[i])
            );
        end
    endgenerate
    
endmodule
