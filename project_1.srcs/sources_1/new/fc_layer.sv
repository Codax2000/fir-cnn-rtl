`timescale 1ns / 1ps

/**
Alex Knowlton
2/6/2023

Fully-connected layer. Entirely combinational with a register at the output. See fc_node.sv for more thorough
details on functionality.
*/

module fc_layer # (
    parameter WORD_SIZE=16,
    parameter INPUT_LAYER_HEIGHT=4,
    parameter OUTPUT_LAYER_HEIGHT=3)(
    input logic clk_i,
    input logic reset_i,
    input logic [INPUT_LAYER_HEIGHT - 1:0][WORD_SIZE - 1:0] data_i,
    input logic [OUTPUT_LAYER_HEIGHT - 1:0][INPUT_LAYER_HEIGHT - 1:0][WORD_SIZE - 1:0] weights_i,
    input logic [OUTPUT_LAYER_HEIGHT - 1:0][WORD_SIZE - 1:0] bias_i,
    output logic  [OUTPUT_LAYER_HEIGHT -1:0][WORD_SIZE - 1:0] data_o
    );
    
    genvar i;
    generate
        for (i = 0; i < OUTPUT_LAYER_HEIGHT; i = i + 1) begin
            fc_node #(
                .WORD_SIZE(WORD_SIZE),
                .INPUT_LAYER_HEIGHT(INPUT_LAYER_HEIGHT)
            ) node (
                .clk_i,
                .reset_i,
                .data_i(data_i),
                .bias_i(bias_i[i]),
                .weights_i(weights_i[i]),
                .data_o(data_o[i])
            );
        end
    endgenerate
    
endmodule
