`timescale 1ns / 1ps
/**
Alex Knowlton
2/28/2023

Convolutional layer module. When start is asserted, handshakes in data with ready/valid
interface and outputs data also with a ready-valid handshake. 

parameters:
    INPUT_LAYER_HEIGHT  : height of input layer (not total number of inputs, just the height), default 64
    KERNEL_WIDTH        : width of kernel used for computation, default 2
    KERNEL_HEIGHT       : height of kernel, default 5
    WORD_SIZE           : number of bits in each piece of data, default 16
    N_SIZE              : number of fractional bits, default 12
    LAYER_NUMBER        : layer number in neural net. used for finding the correct memory file for kernel, default 1
    CONVOLUTION_NUMBER  : kernel number. also used for finding the correct memory file, default 0

control inputs:
    clk_i   : 1-bit : clock signal
    reset_i : 1-bit : reset signal
    start_i : 1-bit : signal to start computation (to delay computation until new outputs are received)

helpful input interface:
    valid_i : 1-bit : valid signal for input handshake
    ready_o : 1-bit : ready signal for input handshake
    data_i  : n-bit : incoming data. size is WORD_SIZE
    
helpful output interface
    yumi_i  : 1-bit : ready signal for output handshake
    valid_o : 1-bit : valid signal for output handshake
    data_o  : n-bit : outgoing data. size is WORD_SIZE

OPTIONAL INPUTS:
if VIVADO is not defined, then add optional write port for the RAM. Add separate data_i port for RAM:
    addr_i  : n-bit : RAM address to write to. size is address width of RAM
    mem_data_i: n-bit: data to write to memory
    
*/

module conv_layer #(

    parameter INPUT_LAYER_HEIGHT=64,
    parameter KERNEL_HEIGHT=5,
    parameter KERNEL_WIDTH=2,
    parameter WORD_SIZE=16,
    parameter N_SIZE=12,
    parameter LAYER_NUMBER=1,
    parameter CONVOLUTION_NUMBER=0) (
    
    input logic clk_i,
    input logic reset_i,
    
    // still need start signal
    input logic start_i,

    // helpful input interface
    input logic valid_i,
    output logic ready_o,
    input logic signed [WORD_SIZE-1:0] data_i,
    
    // helpful output interface
    output logic valid_o,
    input logic yumi_i,
    output logic [WORD_SIZE-1:0] data_o);
    
    
    ////  START CONTROL LOGIC   ////
    // counters and shift registers for memory addresses and logic signals
    localparam INPUT_SIZE = KERNEL_WIDTH * INPUT_LAYER_HEIGHT;
    localparam KERNEL_SIZE = KERNEL_HEIGHT * KERNEL_WIDTH;
    
    logic sum_en_li, add_bias_li;
    
    logic [$clog2(KERNEL_SIZE+1)-1:0] mem_addr_lo;
    logic [$clog2(INPUT_SIZE)-1:0] shift_count_lo;
    
    
    ////    END CONTROL LOGIC   //// 

endmodule