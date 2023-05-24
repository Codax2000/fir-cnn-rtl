`timescale 1ns / 1ps
/**
Alex Knowlton
4/25/2023

This top-level testbench works by taking data from two .mif files: test_inputs.mif and test_outputs_expected.mif
It reads each row as a single packed array (see data values below) and uses it to compute two other files:
test_outputs_actual.csv and test_output_error.csv that can be used for later analysis.

IMPORTANT, PLEASE READ BEFORE RUNNING
Assumes .mif files are in hex format
Make sure to cd into the folder where the repo is stored to ensure the files are saved in the right place.
This module assumes a simple relative path to the ./mem/test_values/ directory, UNTESTED
Written .mif files are 
*/

module tester_tb ();

    parameter NUM_TESTS = 100;
    parameter INPUT_LAYER_HEIGHT = 256;
    parameter WORD_SIZE = 16;
    
    parameter CLOCK_PERIOD = 2;

    // control variables
    logic clk_i, reset_i, start_i;
    
    // input handshake
    logic [INPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] data_i;
    logic valid_i, ready_o;

    // output handshake
    logic valid_o, yumi_i;

    // values for testing
    logic signed [INPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] test_inputs [NUM_TESTS-1:0];
    
    // fc output layer that the FPGA will be writing to
    logic [INPUT_LAYER_HEIGHT*WORD_SIZE-1:0] data_o;


    tester #(
        .WORD_SIZE(WORD_SIZE),
        .NUM_WORDS(INPUT_LAYER_HEIGHT),
        .NUM_TESTS(NUM_TESTS),
        .TEST_INPUT_FILE("test_inputs.mif")
    ) dut (
        // top level control
        .clk_i,
        .reset_i,
        .start_i,
        
        // helpful input handshake
        .ready_o,
        .valid_i,
        .data_i,
        
        // helpful output handshake
        .valid_o,
        .yumi_i,
        .data_o
    );

    
    initial begin
        clk_i = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk_i = ~clk_i;
    end

    // testbench loop
    initial begin
        $readmemh("test_inputs.mif", test_inputs);

        reset_i <= 1'b1;
 start_i <= 1'b0;
 yumi_i <= 1'b0; valid_i <= 1'b1; @(posedge clk_i); @(posedge clk_i);
        reset_i <= 1'b0;    @(posedge clk_i);
        start_i <= 1'b1;    @(posedge clk_i);
        start_i <= 1'b0;

        for (int i = 0; i < NUM_TESTS; i++) begin
            $display("Running test %d",i);
 @(posedge valid_o)
            $display("Expected: %h", test_inputs[i]);
            $display("Actual:   %h", data_o);
            
            if (test_inputs[i] != data_o)
                $stop;
            $display("MATCH!");
            
            yumi_i <= 1'b1;     @(posedge clk_i);
            yumi_i <= 1'b0;

        end
        
        $display("ALL GOOD!!!");
        $stop;
    end

endmodule