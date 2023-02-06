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
    input logic [WORD_SIZE - 1:0] bias_i,
    input logic [INPUT_LAYER_HEIGHT - 1:0][WORD_SIZE - 1:0] weights_i,
    output logic [WORD_SIZE - 1:0] data_o
    );
    
    logic [INPUT_LAYER_HEIGHT - 1:0][WORD_SIZE - 1:0] mults, sum;
    logic [WORD_SIZE - 1:0] bias_sum, out;
    
    // ignore overflow for now
    always_comb begin
        for (integer i = 0; i < INPUT_LAYER_HEIGHT; i = i + 1) begin
            mults[i] = data_i[i] * weights_i[i];
        end
        
        sum[0] = mults[0];
        for (integer j = 1; j < INPUT_LAYER_HEIGHT; j = j + 1) begin
            sum[j] = sum[j - 1] + mults[j];
        end
        
        bias_sum = sum[INPUT_LAYER_HEIGHT - 1] - bias_i;
        
        // ReLU function: if sum is negative, output zero, otherwise output sum
        if (bias_sum[WORD_SIZE - 1])
            out = '0;
        else
            out = bias_sum;
    end
    
    always_ff @(posedge clk_i) begin
        if (reset_i)
            data_o <= '0;
        else
            data_o <= out;
    end
    
endmodule
