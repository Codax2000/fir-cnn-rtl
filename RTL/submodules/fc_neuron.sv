`timescale 1ns / 1ps
/**
Alex Knowlton
4/5/2023

Fully-connected neuron module. Takes control signals from layer and computes the weighted sum
from the input.
*/

module fc_neuron #(
    parameter WORD_SIZE=16,
    parameter PREVIOUS_LAYER_HEIGHT=4,
    parameter LAYER_NUMBER=1,
    parameter NEURON_NUMBER=0 ) (

    input logic signed [WORD_SIZE-1:0] data_i,

    // control signals
    input logic [$clog2(PREVIOUS_LAYER_HEIGHT+1)-1:0] mem_addr_i,
    input logic sum_en,
    input logic add_bias,

    input logic reset_i,
    input logic clk_i,

    output logic signed [WORD_SIZE-1:0] data_o
);

    logic signed [WORD_SIZE*2-1:0] mult_result;
    logic signed [WORD_SIZE-1:0] mem_out, sum_in, sum_n, sum_r;
    
    assign mult_result = data_i * mem_out;
    assign sum_in = add_bias ? mem_out : mult_result[WORD_SIZE-1:0];
    assign sum_n = sum_in + sum_r;
    
    // assign output, no ReLU
    assign data_o = sum_r;

    always_ff @(posedge clk_i) begin
        if (reset_i)
            sum_r <= '0;
        else if (sum_en)
            sum_r <= sum_n;
        else
            sum_r <= sum_r;
    end
    
    // ROM
    ROM #(
        .depth($clog2(PREVIOUS_LAYER_HEIGHT+1)),
        .width(WORD_SIZE),
        .neuron_type(1),
        .layer_number(LAYER_NUMBER),
        .neuron_number(NEURON_NUMBER)
    ) weight_and_bias_mem (
        .clk_i,
        .addr_i(mem_addr_i),
        .data_o(mem_out)
    );
endmodule