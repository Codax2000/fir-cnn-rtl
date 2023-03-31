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
    
    input logic [KERNEL_HEIGHT-1:0][KERNEL_WIDTH-1:0][WORD_SIZE-1:0] data_i,
    input logic [WORD_SIZE-1:0] weight_i,

    input logic [$clog2(KERNEL_HEIGHT * KERNEL_WIDTH + 1)-1:0] input_index,
    input logic add_bias,

    output logic [WORD_SIZE-1:0] data_o
    );
    
    
endmodule

