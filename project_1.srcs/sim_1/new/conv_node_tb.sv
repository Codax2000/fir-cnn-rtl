`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/03/2023 10:52:32 AM
// Design Name: 
// Module Name: fc_node_tb
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
function void assert_equals(expected, actual);
    assert(expected == actual)
        else $display("%3d: Assertion Error. Expected %h, received %h", $time, expected, actual);
    endfunction

module conv_node_tb();

    logic clk, reset;
    logic [1:0][1:0][15:0] kernel, data_li;
    logic [15:0] bias, data_lo;
    
    assign kernel[1][1] = 16'h0003;
    assign kernel[1][0] = 16'h0005;
    assign kernel[0][1] = 16'h0004;
    assign kernel[0][0] = 16'h0001;
    
    assign bias = 16'h000a;
    
    conv_node # (.KERNEL_HEIGHT(2), .KERNEL_WIDTH(2)) DUT (
        .clk_i(clk),
        .reset_i(reset),
        .kernel_i(kernel),
        .data_i(data_li),
        .bias_i(bias),
        .data_o(data_lo)
        );
    
    parameter CLOCK_PERIOD = 100;
    initial begin
        clk = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk = ~clk;
    end 
    
    initial begin
        reset <= 1'b1; @(posedge clk);
        reset <= 1'b0;
        $display("Testing Case 1");
        data_li <= 64'h00010004000b0007; repeat(2) @(posedge clk);
        assert(16'h0040 == data_lo)
            else $display("%3d: Assertion Error.", $time);
        assert_equals(16'h0040, data_lo);
        $display("Testing Case 2");
        data_li <= 64'h0004000300010007; @(posedge clk);
        assert_equals(16'h001c, data_lo);
        $display("Testing Case 3");
        data_li <= 64'h0000000000010003; repeat(3) @(posedge clk);
        assert_equals(16'h0000, data_lo);
        $stop;
    end

endmodule

