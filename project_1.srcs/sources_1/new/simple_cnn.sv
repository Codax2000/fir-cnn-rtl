`timescale 1ns / 1ps

/**
Alex Knowlton
2/7/2023

Simple convolutional neural network
structure: 2 parallel fully-connected layers, followed by 1 convolutional layer, followed by 1 convolutional node
Note the design at the layer level and what needs to go into each layer
*/


module simple_cnn (
    input logic clk_i,
    input logic reset_i,
    input logic [1:0][3:0][15:0] data_i,
    output logic [1:0][15:0] data_o
    );
    
    logic [1:0][1:0][15:0] kernel_li;
    
    // test kernel:
    //  [[ 1 2 ]
    //   [ 3 4 ]]
    assign kernel_li[1][1] = 16'h0001;
    assign kernel_li[1][0] = 16'h0002;
    assign kernel_li[0][1] = 16'h0003;
    assign kernel_li[0][0] = 16'h0004;
    
    /**
    [[ 1 2 3 4 ]
     [ 5 6 7 8 ]
     [ 9 a b c ]]
    */
    logic [2:0][3:0][15:0] weights_left_li;
    assign weights_left_li[2] = 64'h0001000200030004;
    assign weights_left_li[1] = 64'h0005000600070008;
    assign weights_left_li[0] = 64'h0009000a000b000c;
    
    /**
    [[ b a 9 8 ]
     [ 7 6 5 4 ]
     [ 3 2 1 0 ]]
    */
    logic [2:0][3:0][15:0] weights_right_li;
    assign weights_right_li[2] = 64'h000b000a00090008;
    assign weights_right_li[1] = 64'h0007000600050004;
    assign weights_right_li[0] = 64'h0003000200010000;
    
    /**
    [[ 4 5 ]
     [ 8 9 ]
    */
    logic [1:0][1:0][15:0] weights_output_li;
    assign weights_output_li[1] = 32'h00040005;
    assign weights_output_li[0] = 32'h00080009;
    
    /**
    [ 2 4 6 ]
    */
    logic [2:0][15:0] bias_layer1_li; // used for both fully-connected input layers
    assign bias_layer1_li = 48'h000200040006;
    
    /**
    [ 3 7 ]
    */
    logic [1:0][15:0] bias_conv_layer_li;
    assign bias_conv_layer_li = 32'h00030007;
    
    /**
    [ 3 5 ]
    */
    logic [1:0][15:0] bias_output_layer_li;
    assign bias_conv_layer_li = 32'h00030005;   
    
    /**
    parameter WORD_SIZE=16,
    parameter KERNEL_HEIGHT=3,
    parameter KERNEL_WIDTH=4,
    parameter DATA_HEIGHT=5)(
    input logic clk_i,
    input logic reset_i,
    input logic [KERNEL_HEIGHT - 1:0][KERNEL_WIDTH - 1:0][WORD_SIZE - 1:0] kernel_i,
    input logic [DATA_HEIGHT - 1:0][KERNEL_WIDTH - 1:0][WORD_SIZE - 1:0] data_i,
    input logic [DATA_HEIGHT - KERNEL_HEIGHT + 1:0][WORD_SIZE - 1:0] bias_i, // one bias for each piece of output
    output logic [DATA_HEIGHT - KERNEL_HEIGHT + 1:0][WORD_SIZE - 1:0] data_o);
    */
    
    logic [1:0][2:0][15:0] intermediate_1;
    
    fc_layer input_layer_1 (
        .clk_i,
        .reset_i,
        .data_i(data_i[1]),
        .weights_i(weights_left_li),
        .bias_i(bias_layer1_li),
        .data_o(intermediate_1[1])
    );
    
    fc_layer input_layer_2 (
        .clk_i,
        .reset_i,
        .data_i(data_i[0]),
        .weights_i(weights_right_li),
        .bias_i(bias_layer1_li),
        .data_o(intermediate_1[0])
    );
    
    logic [1:0][15:0] intermediate_2;
    
    conv_layer #(
        .KERNEL_HEIGHT(2),
        .KERNEL_WIDTH(2),
        .DATA_HEIGHT(3)
    ) hidden_layer_1 (
        .clk_i,
        .reset_i,
        .kernel_i(kernel_li),
        .bias_i(bias_conv_layer_li),
        .data_i(intermediate_1),
        .data_o(intermediate_2)
    );
    
    fc_layer output_layer_1 (
        .clk_i,
        .reset_i,
        .data_i(intermediate_2),
        .weights_i(weights_output_li),
        .bias_i(bias_output_layer_li),
        .data_o
    );
    
endmodule
