`timescale 1ns / 1ps

/**
Alex Knowlton
2/7/2023

testbench for fully-connected layer, input size 3, output size 2
weights matrix:
[[1 2 3]
 [4 5 6]]
*/

function void assert_equals(expected, actual);
    assert(expected == actual)
        else $display("%3d: Assertion Error. Expected %h, received %h", $time, expected, actual);
    endfunction

module fc_layer_tb();

    parameter WORD_SIZE = 16;
    logic clk, reset;
    logic [2:0][WORD_SIZE - 1:0] data_li;
    logic [1:0][WORD_SIZE - 1:0] data_lo;
    logic [1:0][WORD_SIZE - 1:0] bias_li;
    logic [1:0][2:0][WORD_SIZE - 1:0] weights_li;
    
    assign bias_li[1] = 16'h0005;
    assign bias_li[0] = 16'h0003;
    
    assign weights_li[1][2] = 16'h0001;
    assign weights_li[1][1] = 16'h0002;
    assign weights_li[1][0] = 16'h0003;
    assign weights_li[0][2] = 16'h0004;
    assign weights_li[0][1] = 16'h0005;
    assign weights_li[0][0] = 16'h0006;
    
    fc_layer #(
        .WORD_SIZE(16),
        .INPUT_LAYER_HEIGHT(3),
        .OUTPUT_LAYER_HEIGHT(2)) 
        DUT (
        .clk_i(clk),
        .reset_i(reset),
        .data_i(data_li),
        .weights_i(weights_li),
        .bias_i(bias_li), // one bias for each piece of output
        .data_o(data_lo)
    );
    
    parameter CLOCK_PERIOD = 100;
    initial begin
        clk = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk = ~clk;
    end 
    
    initial begin
        #50;
        reset <= 1'b1; @(posedge clk);
        reset <= 1'b0;
        data_li[2] <= 16'h0001;
        data_li[1] <= 16'h0002;
        data_li[0] <= 16'h0003; #50;
        @(posedge clk);
        assert_equals(32'h0009001d, data_lo); // throws assertion error for some reason, waveform shows correcness
        data_li[2] <= 16'h0003;
        data_li[1] <= 16'h0002;
        data_li[0] <= 16'h0005;
        @(posedge clk);
        assert_equals(32'h00110031, data_lo);
        data_li[2] <= 16'h0000;
        data_li[1] <= 16'h0000;
        data_li[0] <= 16'h0001;
        @(posedge clk);
        assert_equals(32'h00000003, data_lo);
        reset <= 1'b1;
        @(posedge clk);
        
        $stop;
    end

endmodule
