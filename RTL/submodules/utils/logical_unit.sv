`timescale 1ns / 1ps
`define VIVADO
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
`ifdef VIVADO

module logical_unit #(
    parameter WORD_SIZE=16,
    parameter INT_BITS=4,
    parameter FRAC_BITS=WORD_SIZE-INT_BITS) (
    
    input logic signed [WORD_SIZE-1:0] mem_i,
    input logic signed [WORD_SIZE-1:0] data_i,
    
    input logic add_bias,
    input logic sum_en,
    
    input logic clk_i,
    input logic reset_i,

    output logic signed [WORD_SIZE-1:0] data_o
    );
    
    
    
    
    
// CONTROLLER
    
    logic [1:0] SEL;
    always_comb begin
        if (reset_i)
            SEL = 2'd3;
        else if (sum_en) begin
            SEL = add_bias ? 2'd1 : 2'd0;
        end else
            SEL = 2'd2;
    end
    
    
    
    
    
// DATAPATH

    // accumulator register
    logic signed [47:0] full_data;
    logic signed [2*WORD_SIZE-1:0] sum_r;
    dsp_macro_0 dut (
        .CLK(clk_i),
        .A(mem_i),
        .B(add_bias ? 1<<FRAC_BITS : data_i),
        .SEL,
        
        .P(full_data)
    );
    assign sum_r = full_data[2*WORD_SIZE-1:0];
    
    // output logic
    safe_alu #(
        .WORD_SIZE(WORD_SIZE),
        .N_SIZE(WORD_SIZE-INT_BITS),
        .OPERATION("trunc")
    ) truncator (
        .a_i(sum_r),
        .b_i(),
        .data_o(data_o)
    );

endmodule

`else

module logical_unit #(
    parameter WORD_SIZE=16,
    parameter INT_BITS=4,
    parameter FRAC_BITS=WORD_SIZE-INT_BITS) (
    
    input logic signed [WORD_SIZE-1:0] mem_i,
    input logic signed [WORD_SIZE-1:0] data_i,
    
    input logic add_bias,
    input logic sum_en,
    
    input logic clk_i,
    input logic reset_i,

    output logic signed [WORD_SIZE-1:0] data_o
    );    
    
// DATAPATH

    // accumulator register
    logic signed [2*WORD_SIZE-1:0] sum_n, sum_r, add_in;
    always_ff @(posedge clk_i) begin
        if (reset_i)
            sum_r <= '0;
        else
            sum_r <= sum_en ? sum_n: sum_r;
    end

    // accumulator combinational logic
    assign add_in = add_bias ? (mem_i<<FRAC_BITS) : mem_i*data_i;
    
    safe_alu #(
        .WORD_SIZE(2*WORD_SIZE),
        .N_SIZE(WORD_SIZE-INT_BITS),
        .OPERATION("add")
    ) adder (
        .a_i(sum_r),
        .b_i(add_in),
        .data_o(sum_n)
    );
    
    // output logic
    safe_alu #(
        .WORD_SIZE(WORD_SIZE),
        .N_SIZE(WORD_SIZE-INT_BITS),
        .OPERATION("trunc")
    ) truncator (
        .a_i(sum_r),
        .b_i(),
        .data_o(data_o)
    );

endmodule

`endif
