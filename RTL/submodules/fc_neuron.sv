`timescale 1ns / 1ps
`ifndef SYNOPSIS
`define VIVADO
`endif
/**
Alex Knowlton
4/5/2023

Fully-connected neuron module. Takes control signals from layer and computes the weighted sum
from the input. data value must come in one clock cycle after matching memory address to give
memory time to read
*/

module fc_neuron #(
    parameter WORD_SIZE=16,
    parameter N_SIZE=8,
    parameter PREVIOUS_LAYER_HEIGHT=4,
    parameter LAYER_NUMBER=1,
    parameter RAM_ADDRESS_BITS = $clog2(PREVIOUS_LAYER_HEIGHT+1),
    parameter NEURON_NUMBER=0 ) (

    input logic signed [WORD_SIZE-1:0] data_i,

    // control signals
    input logic [RAM_ADDRESS_BITS-1:0] w_addr_i,
    input logic sum_en,
    input logic add_bias,

    input logic reset_i,
    input logic clk_i,

    `ifndef VIVADO
    input logic w_en_i,
    input logic [WORD_SIZE-1:0] w_data_i,
    `endif

    output logic signed [WORD_SIZE-1:0] data_o
);

    logic signed [WORD_SIZE-1:0] mem_out;

    ROM_neuron #(
        .depth(RAM_ADDRESS_BITS),
        .width(WORD_SIZE),
        .neuron_type(1),
        .layer_number(LAYER_NUMBER),
        .neuron_number(NEURON_NUMBER)
    ) weight_and_bias_mem (
        `ifndef VIVADO
        .data_i(w_data_i),
        .wen_i(w_en_i),
        `endif
        .reset_i,
        .clk_i,
        .addr_i(w_addr_i),
        .data_o(mem_out)
    );

    logical_unit #(
        .WORD_SIZE(WORD_SIZE),
        .INT_BITS(WORD_SIZE-N_SIZE)
    ) ALU (
        .mem_i(mem_out),
        .data_i,
        .data_o,
        .add_bias,
        .sum_en,
        .clk_i,
        .reset_i
    );

endmodule