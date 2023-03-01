/**
Alex Knowlton
2/18/2023

1 Node for a convolutional neural network layer. All number are signed, output passed through ReLU
function before sent to output.

Parameters:
KERNEL_WIDTH    :   width of input kernel, default 2
KERNEL_HEIGHT   :   height of input kernel, default 3
WORD_SIZE       :   size of word to use, default 16

Inputs:
data_i  :   [KERNEL_HEIGHT-1:0][KERNEL_WIDTH-1:0][WORD_SIZE-1:0]    : input data
kernel_i:   [KERNEL_HEIGHT-1:0][KERNEL_WIDTH-1:0][WORD_SIZE-1:0]    : input kernel
bias_i  :   [WORD_SIZE-1:0] : input bias
start_i :   input start signal
clk_i   :   input clock
reset_i :   reset signal

Outputs:
data_o  :   [WORD_SIZE-1:0] output data
done_o  :   done signal for handshaking with control logic

*/

module conv_node #(
    parameter WORD_SIZE=16,
    parameter KERNEL_HEIGHT=3,
    parameter KERNEL_WIDTH=2) (
    input logic [KERNEL_HEIGHT-1:0][KERNEL_WIDTH-1:0][WORD_SIZE-1:0] data_i,
    input logic [WORD_SIZE-1:0] kernel_i,
    input logic [WORD_SIZE-1:0] bias_i,
    input logic [$clog2(KERNEL_HEIGHT + 1)-1:0] row_i,
    input logic [$clog2(KERNEL_WIDTH + 1)-1:0] col_i,
    input logic bias_en_i,
    input logic add_en_i,
    input logic done_en_i,
    input logic clk_i,
    input logic reset_i,
    output logic [WORD_SIZE-1:0] data_o);
    
    logic [WORD_SIZE * 2 - 1:0] mult_out;
    logic [WORD_SIZE-1:0] add_to_sum, sum_n, sum_r;

    logic overflow; // always set to 0 for now but there if we need it
    assign overflow = 1'b0;

    assign mult_out = kernel_i * data_i[row_i][col_i];
    assign add_to_sum = add_en_i ? mult_out[WORD_SIZE-1:0] : bias_in;
    assign sum_n = add_to_sum + sum_r;

    // set sum value
    always_ff @(posedge clk_i) begin
        if (reset_i)
            sum_r <= '0;
        else if (overflow)
            sum_r <= {1'b0, (WORD_SIZE-2)'b1)};
        else if (add_en_i || bias_en_i)
            sum_r <= sum_n;
        else
            sum_r <= sum_r;
    end

    // set output value
    always_ff @(posedge clk_i) begin
        if (reset_i)
            data_o <= '0;
        else if (done_en_i) begin
            if (sum_r > 0)
                data_o <= sum_r;
            else
                data_o <= '0;
        end else
            data_o <= data_o;
    end

endmodule

