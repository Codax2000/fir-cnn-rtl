`timescale 1ns / 1ps

module abs_layer_tb ();
    
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
    logic ready_o;
    logic valid_i;
    logic signed [WORD_SIZE-1:0] data_r_i;
    
    // handshake to next layer
    logic valid_o;
    logic ready_i;
    logic signed [WORD_SIZE-1:0] data_r_o;
    
    
    
// DEVICE UNDER TEST
    abs_layer #(.WORD_SIZE(WORD_SIZE)
    ) DUT (.*);
    
    
    
// TESTBENCH
    
    initial begin
        // initialize all inputs
        reset_i <= 0; valid_i <= 0; ready_i <= 0;
        
        // reset
        reset_i <= 1; @(posedge clk_i); reset_i <= 0; @(posedge clk_i);
        
        // state_r = eEMPTY
        valid_i <= 1; data_r_i <= 16'b0000111011010010; @(posedge clk_i) // 0.732469473752462
        
        // state_r = eFULL, data_r_o = 0.732469473752462, valid_o = 1, ready_o = 0
        data_r_i <= 16'b0000000101111111; @(posedge clk_i) // -0.621721030422373
        
        // state_r = eFULL, data_r_o = 0.732469473752462, valid_o = 1, ready_o = 0
        ready_i <= 1; @(posedge clk_i)
        
        // state_r = eFULL, data_r_o = -0.621721030422373, valid_o = 1, ready_o = 1
        data_r_i <= 16'b0000000010101101; @(posedge clk_i) // 0.773024276220328
        data_r_i <= 16'b1111011101101001; @(posedge clk_i) // -0.917345614901317
        data_r_i <= 16'b1111111110100101; @(posedge clk_i) // 0.251466403216965
        data_r_i <= 16'b0000001111111000; @(posedge clk_i) // -0.535625366716028
        data_r_i <= 16'b0000010110111011; @(posedge clk_i) // 1.08386757001342
        data_r_i <= 16'b1111110010101000; @(posedge clk_i) // 0.560921617710491
        data_r_i <= 16'b1111101111000010; @(posedge clk_i) // 0.113087525500705
        
        
        //
        valid_i <= 0; data_r_i <= 16'b0000111110011110; @(posedge clk_i) // -0.107299784013662
        
        // state_r = eEMPTY, data_r_o = 0.113087525500705
        valid_i <= 1; 

        
        @(posedge clk_i); @(posedge clk_i)
        $stop;
    end
    
endmodule

