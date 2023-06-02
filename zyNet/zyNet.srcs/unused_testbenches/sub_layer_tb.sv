`timescale 1ns / 1ps

module sub_layer_tb ();
    
    parameter CLOCK_PERIOD = 10;
    parameter WORD_SIZE=16;
    parameter NUM_INPUTS=2;
    
    
    
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
    logic [1:0] valid_i;
    logic signed [WORD_SIZE-1:0] data1_r_i, data2_r_i;
    
    // handshake to next layer
    logic valid_o;
    logic ready_i;
    logic signed [WORD_SIZE-1:0] data_r_o;
    
    
    
// DEVICE UNDER TEST

    sub_layer #(.WORD_SIZE(WORD_SIZE)
    ) DUT (.*);
    
    
    
// TESTBENCH
    
    initial begin
        // initialize all inputs
        reset_i <= 0; valid_i <= 0; ready_i <= 0;
        
        // reset
        reset_i <= 1; @(posedge clk_i); reset_i <= 0; @(posedge clk_i);
        
		  
        // state_r = eEMPTY
        ready_i <= 1;
        valid_i <= 2'b11;
        data1_r_i <= 16'b0000011010011000; data2_r_i <= 16'b1111000100000101; @(posedge clk_i)
        data1_r_i <= 16'b1111100011011101; data2_r_i <= 16'b1111000101111010; @(posedge clk_i)
        data1_r_i <= 16'b1111001100011100; data2_r_i <= 16'b0000101001011010; @(posedge clk_i)
        data1_r_i <= 16'b0000011000111100; data2_r_i <= 16'b1111101000100110; @(posedge clk_i)
        data1_r_i <= 16'b0000111001101000; data2_r_i <= 16'b1111000100011010; @(posedge clk_i)
        
        
        valid_i <= 1; // 0.128021624282094
		  
		  
		  
        @(posedge clk_i); @(posedge clk_i)
        $stop;
    end
    
endmodule

