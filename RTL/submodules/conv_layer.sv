`timescale 1ns / 1ps
/**
Alex Knowlton & Eugene Liu
2/28/2023

Convolutional layer module. Outputs done when all layers finished and biased. On start,
takes data in one word at a time and outputs data in parallel via valid-ready handshakes.

Parameters:
    INPUT_LAYER_HEIGHT  : height of input layer (not total number of inputs, just the height)
    KERNEL_WIDTH        : width of kernel used for computation
    KERNEL_HEIGHT       : height of kernel
    WORD_SIZE           : number of bits in each piece of data
    INT_BITS            : the 'n' of n.m fixed point notation.
    LAYER_NUMBER        : layer number in neural net. used for finding the correct memory file for kernel
    CONVOLUTION_NUMBER  : kernel number. also used for finding the correct memory file
    
Derived Parameters
    KERNEL_SIZE : the number of weight learnables in a kernel
    NUM_SETS    : the number of whole KERNEL_SIZE+1 word chunks (sets) that the input tensor can be divided into
    REMAINDER   : the number of remaining words after dividing the input tensor into sets

Inputs-Outputs
    clk_i   : clock signal
    reset_i : reset signal
    start_i : signal to start computation (to delay computation until new outputs are received)

    ready_o : handshake to prev layer. Indicates this layer is ready to recieve
    valid_i : handshake to prev layer. Indicates prev layer has valid data
    data_i  : handshake to prev layer. The parallel data from the prev layer to this layer
    
    valid_o : handshake to next layer. Indicates this layer has valid data
    ready_i : handshake to next layer. Indicates next layer is ready to receive
    data_o  : handshake to next layer. The data from this layer to the next layer
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
    parameter SET_SIZE    = KERNEL_SIZE+KERNEL_WIDTH,
    parameter NUM_SETS    = $rtoi($floor($itor(INPUT_LAYER_HEIGHT*KERNEL_WIDTH)/$itor(SET_SIZE))),
    parameter REM_WORDS   = (INPUT_LAYER_HEIGHT*KERNEL_WIDTH)%(SET_SIZE),
    parameter REM_OUTPUTS = REM_WORDS/KERNEL_WIDTH+2) (
    
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
        .MAX_INPUT_SIZE(KERNEL_HEIGHT+1),
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