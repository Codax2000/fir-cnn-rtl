`timescale 1ns / 1ps
/**
Alex Knowlton
2/18/2023

1 Node for a convolutional neural network layer. All number are signed, output passed through ReLU
function before sent to output.
*/

module conv_node #(
    parameter WORD_SIZE=16,
    parameter KERNEL_HEIGHT=3,
    parameter KERNEL_WIDTH=2) (
    input logic clk_i,
    input logic reset_i,
    
    // control signal from top
    input logic start_i,
    input logic ps,

    input logic [KERNEL_HEIGHT-1:0][KERNEL_WIDTH-1:0][WORD_SIZE-1:0] data_i,
    input logic [WORD_SIZE-1:0] weight_i,

    input logic [$clog2(KERNEL_HEIGHT * KERNEL_WIDTH + 1)-1:0] input_index,
    input logic add_bias,

    output logic [WORD_SIZE-1:0] data_o
    );
    
    // transpose input data into one vector
    logic [KERNEL_HEIGHT * KERNEL_WIDTH - 1:0][WORD_SIZE-1:0] data_transpose;
    
    integer row, col;
    always_comb begin
        for (col = 0; col < KERNEL_WIDTH; col = col + 1) begin
            for (row = 0; row < KERNEL_HEIGHT; row = row + 1) begin
                data_transpose[col * KERNEL_HEIGHT + row] = data_i[row][col];
            end
        end
    end
    
    logic extra_bit;
    logic [WORD_SIZE * 2 - 1:0] mult_result;
    logic [WORD_SIZE - 1:0] sum_n, sum_r, adder_in;
    logic [$clog2(KERNEL_HEIGHT * KERNEL_WIDTH + 1)-1:0] input_index_cond;
    
    assign adder_in = add_bias ? weight_i : mult_result[WORD_SIZE-1:0];
    assign input_index_cond = add_bias ? '0 : input_index;
    assign mult_result = weight_i * data_transpose[input_index_cond];
    assign {extra_bit, sum_n} = adder_in + sum_r;

    always_ff @(posedge clk_i) begin
        if (reset_i | start_i)
            sum_r <= '0;
        else if (ps == 1'b0)
            sum_r <= sum_r;
        else
            sum_r <= sum_n;
        
        if (start_i)
            data_o <= sum_r;
        else
            data_o <= data_o;
    end
endmodule

