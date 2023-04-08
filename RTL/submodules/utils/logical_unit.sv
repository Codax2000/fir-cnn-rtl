`timescale 1ns / 1ps
/**
Alex Knowlton
4/7/2023

logical unit for neural network. Implements fixed-point multiplication and addition, also saturates the output if overflow occurs.

parameters:
    WORD_SIZE   :   number of bits in input data buses. default 16.
    INT_BITS    :   number of bits for integer in fixed point. default 8. set equal to
                    WORD_SIZE to get signed integer multiplication

inputs:
    mem_i   :   data bus. input value from memory, signed.
    data_i  :   data bus. input data, signed.
    add_bias:   control signal. if true, adds mem_i to rolling sum instead of mem_i * data_i.
    sum_en  :   control signal. if true, enables sum to add next value to current sum.
    clk_i   :   clock signal.
    reset_i :   reset signal. if asserted, sets output data to 0.

outputs:
    data_o  :   data bus. weighted sum of inputs, signed. if overflow occurs either in multiplication or addition,
                saturates the output to be either all the way high or all the way low

*/

module logical_unit #(
    parameter WORD_SIZE=16,
    parameter INT_BITS=8 ) (
    
    input logic signed [WORD_SIZE-1:0] mem_i,
    input logic signed [WORD_SIZE-1:0] data_i,
    
    input logic add_bias,
    input logic sum_en,
    
    input logic clk_i,
    input logic reset_i,

    output logic signed [WORD_SIZE-1:0] data_o
    );

    logic signed [2*WORD_SIZE-1:0] mult_result;
    logic signed [WORD_SIZE-1:0] add_in, sum_n, sum_r;
    logic sum_carry_out;

    assign mult_result = mem_i * data_i;
    assign add_in = add_bias ? mem_i : mult_result[2*WORD_SIZE-INT_BITS-1:WORD_SIZE-INT_BITS];
    assign {sum_carry_out, sum_n} = {sum_r[WORD_SIZE-1], sum_r} + {add_in[WORD_SIZE-1], add_in};

    // overflow logic
    logic overflow, overflow_flag, underflow, underflow_flag;
    overflow #(
        .WORD_SIZE(WORD_SIZE),
        .INT_BITS(INT_BITS)
    ) overflow_tracker (
        .mult_result,
        .sum_carry_out,
        .sum_n,
        .clk_i,
        .reset_i,
    
        .overflow,
        .underflow,
        .underflow_flag,
        .overflow_flag
    );

    
    // output at clock edge
    always_ff @(posedge clk_i) begin
        if (reset_i)
            sum_r <= '0;
        else if (sum_en) begin
            if (overflow_flag || overflow && !underflow_flag) begin
                sum_r[WORD_SIZE-1] <= 1'b0;
                sum_r[WORD_SIZE-2:0] <= '1;
            end else if (underflow_flag || underflow && !overflow_flag) begin
                sum_r[WORD_SIZE-1] <= 1'b1;
                sum_r[WORD_SIZE-2:0] <= '0;
            end else
                sum_r <= sum_n;
        end else begin
            sum_r <= sum_r;
        end
    end
    
    assign data_o = sum_r;

endmodule