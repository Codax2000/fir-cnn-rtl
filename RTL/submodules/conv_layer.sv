`timescale 1ns / 1ps
/**
Alex Knowlton & Eugene Liu
2/28/2023

Convolutional layer module. Outputs done when all layers finished and biased. On start,
takes data in one word at a time and outputs data in parallel via valid-ready handshakes.

parameters:
    INPUT_LAYER_HEIGHT  : height of input layer (not total number of inputs, just the height)
    KERNEL_WIDTH        : width of kernel used for computation
    KERNEL_HEIGHT       : height of kernel
    WORD_SIZE           : number of bits in each piece of data
    INT_BITS            : the 'n' of n.m fixed point notation.
    LAYER_NUMBER        : layer number in neural net. used for finding the correct memory file for kernel
    CONVOLUTION_NUMBER  : kernel number. also used for finding the correct memory file

inputs:
    clk_i   : 1-bit : clock signal
    reset_i : 1-bit : reset signal
    start_i : 1-bit : signal to start computation (to delay computation until new outputs are received)

    valid_i : 1-bit : valid signal for input handshake
    yumi_i  : 1-bit : ready signal for output handshake

    data_i  : n-bit : incoming data. size is WORD_SIZE
    

outputs:
    data_o  : n-bit : outgoing data. packed array of [INPUT_LAYER_HEIGHT - KERNEL_HEIGHT + 1][WORD_SIZE] bits,
                      where least significant word is equivalent to output[0], which should correlate to Rx[0].
    ready_o : 1-bit : ready signal for input handshake
    valid_o : 1-bit : valid signal for output handshake
*/

module conv_layer #(

    parameter INPUT_LAYER_HEIGHT=64,
    parameter KERNEL_HEIGHT=16,
    parameter KERNEL_WIDTH=1,
    parameter WORD_SIZE=16,
    parameter INT_BITS=4,
    parameter LAYER_NUMBER=1,
    parameter CONVOLUTION_NUMBER=0,
    
    // derived parameters. Don't need to touch!
    parameter KERNEL_SIZE = KERNEL_WIDTH*KERNEL_HEIGHT,
    parameter NUM_SETS    = $rtoi($floor($itor(INPUT_LAYER_HEIGHT*KERNEL_WIDTH)/$itor(KERNEL_SIZE+1))),
    parameter REMAINDER   = (INPUT_LAYER_HEIGHT*KERNEL_WIDTH)%(KERNEL_SIZE+1)) (
    
    // top-level signals
    input logic clk_i,
    input logic reset_i,
    input logic start_i,

    // helpful interface to prev layer
    input logic valid_i,
    output logic ready_o,
    input logic signed [WORD_SIZE-1:0] data_i,
    
    // helpful interface to next layer
    output logic valid_o,
    input logic ready_i,
    output logic signed [KERNEL_HEIGHT:0][WORD_SIZE-1:0] data_o);
    
    
    
    
    
 // DATAPATH
    
    logic conv_valid_lo, piso_ready_lo;
    logic [KERNEL_HEIGHT:0][WORD_SIZE-1:0] conv_data_lo;
    logic [$clog2(KERNEL_SIZE+1)-1:0] conv_data_size_lo;
    convolve #(
        .INPUT_LAYER_HEIGHT(INPUT_LAYER_HEIGHT),
        .KERNEL_HEIGHT(KERNEL_HEIGHT),
        .KERNEL_WIDTH(KERNEL_WIDTH),
        .WORD_SIZE(WORD_SIZE),
        .INT_BITS(INT_BITS),
        .LAYER_NUMBER(LAYER_NUMBER),
        .CONVOLUTION_NUMBER(CONVOLUTION_NUMBER)
    ) convolver (
        // top-level signals
        .clk_i,
        .reset_i,
        .start_i,
    
        // helpful interface to prev layer
        .valid_i,
        .ready_o,
        .data_i,
        
        // helpful interface to next layer
        .valid_o(conv_valid_lo),
        .ready_i(piso_ready_lo),
        .data_o(conv_data_lo),
        .data_size_o(conv_data_size_lo)
    );
    
    piso_layer #(
        .MAX_INPUT_SIZE(KERNEL_SIZE+1),
        .WORD_SIZE(WORD_SIZE)
    ) piso (
        // top-level control
        .clk_i,
        .reset_i,
        
        // helpful handshake to prev layer
        .valid_i(conv_valid_lo),
        .ready_o(piso_ready_lo),
        .data_i(conv_data_lo),
        .data_size_i(conv_data_size_lo),
    
        // helpful handshake to next layer
        .valid_o,
        .ready_i,
        .data_o
    );

endmodule