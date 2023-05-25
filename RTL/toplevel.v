`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/23/2023 11:37:24 PM
// Design Name: 
// Module Name: toplevel
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module toplevel #(
    parameter NUM_TESTS = 10
    ) (
    input wire clk_i,
    input wire reset_i,
    input wire begin_i
    );
    
    localparam INPUT_LAYER_HEIGHT = 128;
    localparam OUTPUT_LAYER_HEIGHT = 10;
    localparam WORD_SIZE = 16;
    
    //// IP MODULES FOR CLK AND RESET
    wire clk_lo, reset_lo, clk_locked_lo;
    clk_wiz_0 clk_gen (
        .reset(reset_i),
        .clk_in1(clk_i),
        .clk_out1(clk_lo),
        .locked(clk_locked_lo)
    );
    
    proc_sys_reset_0 reset_gen (
        .slowest_sync_clk(clk_lo),
        .ext_reset_in(reset_i),
        .aux_reset_in(reset_i),
        .mb_debug_sys_rst(1'b0),
        .dcm_locked(clk_locked_lo),
        .bus_struct_reset(reset_lo)
    );
    
    //// DATAPATH
    // test output handshake
    wire test_valid_lo, test_ready_lo;
    wire [2*INPUT_LAYER_HEIGHT*WORD_SIZE-1:0] test_data_lo;
    
    // serializer output handshake
    wire fcin_valid_lo, fcin_ready_lo;
    wire [WORD_SIZE-1:0] fcin_data_lo;
    
    // cnn output handshake
    wire cnn_valid_lo, cnn_ready_lo;
    wire [OUTPUT_LAYER_HEIGHT*WORD_SIZE-1:0] cnn_data_lo;
    
    // extra signals
    wire conv_ready_lo;
    wire conv_start_li;
    
    assign data_o = cnn_data_lo;
    
    assign conv_start_li = test_ready_lo && cnn_valid_lo;
    
    // test input generator
    tester #(
        .WORD_SIZE(16),
        .NUM_WORDS(INPUT_LAYER_HEIGHT*2),
        .OUTPUT_SIZE(10),
        .NUM_TESTS(NUM_TESTS),
        .TEST_INPUT_FILE("test_inputs.mif")
    ) test_inputs (
        .start_i(begin_i),
        .clk_i(clk_lo),
        .reset_i(reset_lo),
        
        // helpful input handshake
        .ready_o(test_ready_lo),
        .valid_i(cnn_valid_lo),
        .data_i(cnn_data_lo),
        
        // helpful output handshake
        .valid_o(test_valid_lo),
        .yumi_i(fcin_ready_lo),
        .data_o(test_data_lo)        
    );
    
    
    fc_output_layer #(
        .LAYER_HEIGHT(INPUT_LAYER_HEIGHT*2),
        .WORD_SIZE(WORD_SIZE)
    ) serializer (
        .clk_i(clk_lo),
        .reset_i(reset_lo),
    
        // helpful handshake to prev layer
        .valid_i(test_valid_lo),
        .ready_o(fcin_ready_lo),
        .data_i(test_data_lo),
    
        // helpful handshake to next layer
        .valid_o(fcin_valid_lo),
        .yumi_i(cnn_ready_lo),
        .data_o(fcin_data_lo)
    );
    
    zyNet cnn (
    
        // top level signals
        .clk_i(clk_lo),
        .reset_i(reset_lo),
        
        .start_i(conv_start_li || begin_i),
        .conv_ready_o(conv_ready_lo),
        
        // helpful handshake in
        .data_i(fcin_data_lo),
        .valid_i(fcin_valid_lo),
        .ready_o(cnn_ready_lo),
    
        // helpful handshake out
        .data_o(cnn_data_lo),
        .valid_o(cnn_valid_lo),
        .yumi_i(test_ready_lo)
    );
    
    //// DEBUG CORE
    
    
    ila_0 ila_debug (
        .clk(clk_lo),
        .probe0(cnn_data_lo),
        .trig_in(conv_start_li || begin_i)
    );
    
endmodule
