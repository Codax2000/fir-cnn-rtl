`timescale 1ns / 1ps
`ifndef SYNOPSIS
`define VIVADO
`endif
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

module zyNet_matlab_tb ();

    // TODO: Change test parameters as necessary
    parameter NUM_TESTS = 10;
    parameter CLOCK_PERIOD = 40; // 40 ns clock, a.k.a. 25 MHz, change if timing changes

    // TODO: Set any necessary model parameters here
    parameter INPUT_LAYER_HEIGHT = 256; // 60 samples, 2 '0' elements on either side  256 32
    parameter OUTPUT_LAYER_HEIGHT = 10;
    parameter WORD_SIZE = 16;
    parameter N_SIZE=12;
    parameter OUTPUT_SIZE=10;
    
    parameter MEM_WORD_SIZE=21;
    parameter LAYER_SELECT_BITS=2;
    parameter RAM_SELECT_BITS=8;
    parameter RAM_ADDRESS_BITS=9;
    
    localparam INT_BITS = WORD_SIZE - N_SIZE;
    
    // control variables
    logic clk_i, reset_i, start_i, conv_ready_o;
    
    // input handshake
    logic [INPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] data_i ;
    logic valid_i, ready_o;

    // output handshake
    logic valid_o, yumi_i;
    logic signed [OUTPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] data_o;

    // values for testing
    logic [INPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] test_inputs [NUM_TESTS-1:0];
    logic [OUTPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] expected_outputs [NUM_TESTS-1:0];
    logic [OUTPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] current_expected_output;
    
    // fc output layer for easily sending data to the model
    logic [WORD_SIZE-1:0] serial_out;
    logic fcin_valid_i, fcin_ready_o;

    fc_output_layer #(
        .LAYER_HEIGHT(INPUT_LAYER_HEIGHT),
        .WORD_SIZE(WORD_SIZE) 
    ) input_serializer (
        .clk_i,
        .reset_i,
    
        // helpful handshake to prev layer
        .valid_i(fcin_valid_i),
        .ready_o(fcin_ready_o),
        .data_i(data_i),

        // demanding handshake to next layer
        .valid_o(valid_i),
        .yumi_i(ready_o),
        .data_o(serial_out)
    );

    zyNet #(
        .WORD_SIZE(WORD_SIZE),
        .N_SIZE(N_SIZE),
        .OUTPUT_SIZE(OUTPUT_SIZE),
    
        .MEM_WORD_SIZE(MEM_WORD_SIZE),
        .LAYER_SELECT_BITS(LAYER_SELECT_BITS),
        .RAM_SELECT_BITS(RAM_SELECT_BITS),
        .RAM_ADDRESS_BITS(RAM_ADDRESS_BITS)
    ) DUT (
        .clk_i,
        .reset_i,

        .start_i,
        .conv_ready_o,

        .data_i(serial_out),
        .ready_o,
        .valid_i,

        .data_o,
        .valid_o,
        .yumi_i
    );
    
    initial begin
        clk_i = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk_i = ~clk_i;
    end
    

    // testbench loop
    int measured_outputs, errors;
    initial begin
        $readmemh("test_inputs.mif", test_inputs);
        $readmemh("test_outputs_expected.mif", expected_outputs);
        // check these file paths and change them locally, or this will fail
        measured_outputs = $fopen("C:/Users/alexk/Documents/Projects/fir-cnn-rtl/mem/test_values/test_outputs_actual.csv", "w");
        errors = $fopen("C:/Users/alexk/Documents/Projects/fir-cnn-rtl/mem/test_values/test_outputs_errors.csv", "w");
        reset_i <= 1'b1;
        start_i <= 1'b0;
        yumi_i <= 1'b0;     repeat(4) @(posedge clk_i);
        reset_i <= 1'b0;    @(posedge clk_i);

        for (int i = 0; i < NUM_TESTS; i++) begin
            $display("Running test %d",i);
            current_expected_output <= expected_outputs[i];
            data_i <= test_inputs[i];   @(posedge clk_i);
            fcin_valid_i <= 1'b1;       @(posedge clk_i);
            fcin_valid_i <= 1'b0;       @(posedge clk_i);
            start_i <= 1'b1;            @(posedge clk_i);
            start_i <= 1'b0;            @(posedge clk_i);
                                        @(posedge valid_o);
                                        @(posedge clk_i);
                                        
            for (int j = 0; j < OUTPUT_LAYER_HEIGHT-1; j++) begin
                $fwrite(measured_outputs, "%h,", data_o[j]);
                
                $fwrite(errors, "%f,", $itor(data_o[j])/(2.0**(WORD_SIZE-INT_BITS)) - $itor(current_expected_output[j])/(2.0**(WORD_SIZE-INT_BITS)));
                $display("%b: %f-%f = %f,",current_expected_output[j],$itor(data_o[j])/(2.0**(WORD_SIZE-INT_BITS)),$itor(current_expected_output[j])/(2.0**(WORD_SIZE-INT_BITS)),$itor(data_o[j])/(2.0**(WORD_SIZE-INT_BITS)) - $itor(current_expected_output[j])/(2.0**(WORD_SIZE-INT_BITS)));
            end
            $fwrite(measured_outputs, "%h\n", data_o[OUTPUT_LAYER_HEIGHT-1]);
            $fwrite(errors, "%f\n", $itor(data_o[OUTPUT_LAYER_HEIGHT-1])/(2.0**(WORD_SIZE-INT_BITS)) - $itor(current_expected_output[OUTPUT_LAYER_HEIGHT-1])/(2.0**(WORD_SIZE-INT_BITS)));
            $display("%b: %f-%f = %f\n",current_expected_output[OUTPUT_LAYER_HEIGHT-1],$itor(data_o[OUTPUT_LAYER_HEIGHT-1])/(2.0**(WORD_SIZE-INT_BITS)),$itor(current_expected_output[OUTPUT_LAYER_HEIGHT-1])/(2.0**(WORD_SIZE-INT_BITS)),$itor(data_o[OUTPUT_LAYER_HEIGHT-1])/(2.0**(WORD_SIZE-INT_BITS)) - $itor(current_expected_output[OUTPUT_LAYER_HEIGHT-1])/(2.0**(WORD_SIZE-INT_BITS)));

            yumi_i <= 1'b1;             @(posedge clk_i);
            yumi_i <= 1'b0;             @(posedge clk_i);
        end

        $fclose(measured_outputs);
        $fclose(errors);

        $stop;
    end

endmodule