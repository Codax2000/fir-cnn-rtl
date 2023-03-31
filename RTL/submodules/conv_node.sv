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
    
    // delay index to line up weights with input data
    logic [$clog2(KERNEL_HEIGHT * KERNEL_WIDTH + 1)-1:0] add_index;
    assign add_index = input_index - 1;
    
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
    
    assign adder_in = add_bias ? mult_result[WORD_SIZE-1:0] : weight_i;
    assign mult_result = weight_i * data_transpose[add_index];
    assign {extra_bit, sum_n} = adder_in + sum_r;

    always_ff @(posedge clk_i) begin
        if (reset_i | add_bias)
            sum_r <= '0;
        else
            sum_r <= sum_n;
    end
endmodule

