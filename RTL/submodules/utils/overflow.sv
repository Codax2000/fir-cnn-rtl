`timescale 1ns / 1ps
/**
Alex Knowlton
4/7/2023

Overflow module.

parameters
    WORD_SIZE:  number of bits in data
    INT_BITS :  number of bits in int
inputs:
    mult_result     : result of multiplier
    extra_add_bit   : carry out of sum
    sum_n           : output of sum
    clk_i           : input clock
    reset_i         : input reset, clears all flags
outputs:
    overflow        : combinational signal, true if overflow has occurred
    underflow       : combinational signal, true if underflow has occurred
    overflow_flag   : stays true if overflow has been high since last reset
    underflow_flag  : stays true if underflow has been high since last reset
*/

module overflow #(
    parameter WORD_SIZE=16,
    parameter INT_BITS=8 ) (
    
    input logic [2*WORD_SIZE-1:0] mult_result,
    input logic sum_carry_out,
    input logic [WORD_SIZE-1:0] sum_n,
    input logic clk_i,
    input logic reset_i,
    
    output logic overflow,
    output logic underflow,
    output logic underflow_flag,
    output logic overflow_flag);

    // overflow/underflow signals, purely combinational
    logic overflow, underflow, overflow_flag, underflow_flag;
    logic overflow_add, overflow_mult, underflow_add, underflow_mult;
    
    assign overflow_add = {sum_carry_out, sum_n[WORD_SIZE-1]} == 2'b01;
    assign overflow_mult = (mult_result[2*WORD_SIZE-1] == 1'b0) && mult_result[2*WORD_SIZE-1:2*WORD_SIZE-INT_BITS-1] != '0;
    assign underflow_add = {sum_carry_out, sum_n[WORD_SIZE-1]} == 2'b10;
    assign underflow_mult = (mult_result[2*WORD_SIZE-1] == 1'b1) && mult_result[2*WORD_SIZE-1:2*WORD_SIZE-INT_BITS-1] != '1;
    
    assign overflow = overflow_add || overflow_mult;
    assign underflow = underflow_add || underflow_mult;
    
    always_ff @(posedge clk_i) begin
        if (reset_i)
            overflow_flag <= 1'b0;
        else if (overflow && !underflow_flag)
            overflow_flag <= 1'b1;
        else
            overflow_flag <= overflow_flag;

        if (reset_i)
            underflow_flag <= 1'b0;
        else if (underflow && !overflow_flag)
            underflow_flag <= 1'b1;
        else
            underflow_flag <= underflow_flag;
    end

endmodule