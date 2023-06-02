`timescale 1ns / 1ps

module multi_input_layer_ctrl_tb ();
    
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
    logic en_o;
    
    // handshake to prev layer
    logic ready_o;
    logic [NUM_INPUTS-1:0] valid_i;
    
    // handshake to next layer
    logic valid_o;
    logic ready_i;
    
    
    
    
// DEVICE UNDER TEST
    multi_input_layer_ctrl #(.WORD_SIZE(WORD_SIZE),.NUM_INPUTS(NUM_INPUTS)
    ) DUT (.*);
    
    
    
// TESTBENCH
    
    initial begin
        // initialize all inputs
        reset_i <= 0; valid_i <= 0; ready_i <= 0;
        
        // reset
        reset_i <= 1; @(posedge clk_i); reset_i <= 0; @(posedge clk_i)
        
    // BEGIN TESTING
    
        // state_r = eEMPTY. Nothing should happen until all valid_i bits are high
        ready_i <= 1; @(posedge clk_i)
        valid_i <= 2'b01; @(posedge clk_i)
        valid_i <= 2'b10; @(posedge clk_i)
        
        ready_i <= 0; @(posedge clk_i)
        valid_i <= 2'b00; @(posedge clk_i)
        valid_i <= 2'b01; @(posedge clk_i)
        valid_i <= 2'b10; @(posedge clk_i)
        valid_i <= 2'b11; @(posedge clk_i)
        
        // state_r = eFULL.
        valid_i <= 2'b00; @(posedge clk_i)
        valid_i <= 2'b01; @(posedge clk_i)
        valid_i <= 2'b10; @(posedge clk_i)
        valid_i <= 2'b11; @(posedge clk_i)
        
        ready_i <= 1; @(posedge clk_i)
        valid_i <= 2'b01; @(posedge clk_i)
        
        // state_r = eEMPTY.
        
        @(posedge clk_i); @(posedge clk_i)
        $stop;
    end
    
endmodule