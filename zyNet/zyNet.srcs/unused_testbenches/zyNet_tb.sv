`timescale 1ns / 1ps

module zyNet_tb ();
    
    parameter CLOCK_PERIOD = 10;
    parameter WORD_SIZE=16;
    
    
    
// VARIABLES
    
    // input clock
    logic clk_i;
    initial begin
        clk_i = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk_i = ~clk_i;
    end
    
    logic reset_i;
    
    // handshake to prev layer
    logic start_i;
    logic signed [WORD_SIZE-1:0] data_i;
    
    // handshake to next layer
    logic valid_o;
    logic yumi_i;
    logic signed [WORD_SIZE-1:0] data_o;
    
    
    
    
    
// DATAPATH

    // counter
    logic en;
    logic [22:0] count_r;
    always_ff @(posedge clk_i) begin
        if (reset_i)
            count_r <= 0;
        else
            count_r <= en ? count_r+1 :  count_r;
    end

    // test ROM
    ROM_inferred #(
       .ADDR_WIDTH(23),
       .WORD_SIZE(WORD_SIZE),
       .MEM_INIT("testData.mem")
    ) rom (
       .clk_i,
       .reset_i,
       
       .addr_i(count_r),
       .data_o(data_i)
    );
    
    // DUT
    zyNet #(
        .WORD_SIZE(WORD_SIZE),
        .INT_BITS(4)
    ) dut (
    .*);
    
    
    
    
    
// TESTBENCH
    
    initial begin
        // initialize all inputs
        reset_i <= 0; en <= 1;
        
        // reset
        reset_i <= 1; @(posedge clk_i); reset_i <= 0;
        repeat(26) @(posedge clk_i);
        start_i <= 1; @(posedge clk_i);
        
        repeat(100) @(posedge clk_i);
        $stop;
    end
    
endmodule