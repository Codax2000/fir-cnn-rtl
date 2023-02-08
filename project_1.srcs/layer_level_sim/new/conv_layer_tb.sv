`timescale 1ns / 1ps

/**
Alex Knowlton
2/7/2023

testbench for convolutional layer, kernel size 3x2:
kernel:
[[1, 2],
 [4, 5],
 [2, 7]]

Tests multiple inputs and ensures they come out on the next clock cycle
input layer: 4x2
output layer: 2x1
*/

function void assert_equals(expected, actual);
    assert(expected == actual)
        else $display("%3d: Assertion Error. Expected %h, received %h", $time, expected, actual);
    endfunction

module conv_layer_tb();

    parameter WORD_SIZE = 16;
    logic clk, reset;
    logic [3:0][1:0][WORD_SIZE - 1:0] data_li;
    logic [1:0][WORD_SIZE - 1:0] data_lo;
    logic [1:0][WORD_SIZE - 1:0] bias_li;
    logic [2:0][1:0][WORD_SIZE - 1:0] kernel;
    
    assign kernel[2][1] = 16'h0001;
    assign kernel[2][0] = 16'h0002;
    assign kernel[1][1] = 16'h0004;
    assign kernel[1][0] = 16'h0005;
    assign kernel[0][1] = 16'h0002;
    assign kernel[0][0] = 16'h0007;
    
    assign bias_li[1] = 16'h0005;
    assign bias_li[0] = 16'h0003;
    
    conv_layer #(
        .WORD_SIZE(16),
        .KERNEL_HEIGHT(3),
        .KERNEL_WIDTH(2),
        .DATA_HEIGHT(4) ) 
        DUT (
        .clk_i(clk),
        .reset_i(reset),
        .kernel_i(kernel),
        .data_i(data_li),
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
        data_li[3][1] <= 16'h0001;
        data_li[3][0] <= 16'h0002;
        data_li[2][1] <= 16'h0003;
        data_li[2][0] <= 16'h0004;
        data_li[1][1] <= 16'h0005;
        data_li[1][0] <= 16'h0006;
        data_li[0][1] <= 16'h0007;
        data_li[0][0] <= 16'h0008;
        @(posedge clk);
        assert_equals(32'h00540080, data_lo);
        data_li[3][1] <= 16'h0003;
        data_li[3][0] <= 16'h0002;
        data_li[2][1] <= 16'h0005;
        data_li[2][0] <= 16'h0001;
        data_li[1][1] <= 16'h000a;
        data_li[1][0] <= 16'h000f;
        data_li[0][1] <= 16'h0006;
        data_li[0][0] <= 16'h0001;
        @(posedge clk);
        assert_equals(32'h0098008a, data_lo);
        data_li[3][1] <= 16'h0000;
        data_li[3][0] <= 16'h0000;
        data_li[2][1] <= 16'h0002;
        data_li[2][0] <= 16'h0000;
        data_li[1][1] <= 16'h0000;
        data_li[1][0] <= 16'h0000;
        data_li[0][1] <= 16'h0000;
        data_li[0][0] <= 16'h0000;
        @(posedge clk);
        assert_equals(32'h00030000, data_lo);
        reset <= 1'b1;
        @(posedge clk);
        
        $stop;
    end

endmodule
