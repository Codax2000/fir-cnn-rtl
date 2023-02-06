`timescale 1ns / 1ps

function void assert_equals(expected, actual);
    assert(expected == actual)
        else $display("%3d: Assertion Error. Expected %h, received %h", $time, expected, actual);
    endfunction
    
module fc_node_tb();

    logic clk, reset;
    // use default word size of 16 and input layer height of 4
    logic [3:0][15:0] data_li, weights_li;
    logic [15:0] bias_li, data_lo;
    
    assign bias_li = 16'h000a; // test bias of 10
    assign weights_li = 64'h0002000a00030005; // [2 10 3 5] weight matrix to test
    
    fc_node DUT (
        .clk_i(clk),
        .reset_i(reset),
        .data_i(data_li),
        .bias_i(bias_li),
        .weights_i(weights_li),
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
        data_li <= 64'h0001000300020001; @(posedge clk);
        assert_equals(64'h0000_0000_0000_0021, data_lo); // 44 in decimal
        data_li <= 64'h0002_0001_0001_0002; @(posedge clk);
        assert_equals(64'h0000_0000_0000_0011, data_lo);
        data_li <= 64'h0001_0000_0001_0000; @(posedge clk);
        assert_equals(64'h0000_0000_0000_0000, data_lo); repeat(3) @(posedge clk);
        
        $stop;
    end

endmodule

