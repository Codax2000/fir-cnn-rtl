/**
Alex Knowlton
4/3/2023

Rewritten fully-connected layer for readability and functionality, since this supports
layers of differing sizes. Assumes FIFO on both input and output.
*/

module fc_layer #(
    parameter WORD_SIZE=16,
    parameter LAYER_HEIGHT=5,
    parameter LAYER_NUMBER=1 ) (
    
    // demanding interface
    input logic [WORD_SIZE-1:0] data_i,
    input logic empty_i,
    output logic wen_o,
    
    // demanding interface
    output logic [WORD_SIZE-1:0] data_o,
    input logic full_i,
    output logic ren_o,

    input logic reset_i,
    input logic clk_i
    );


endmodule