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

module zyNet_matlab_tb ();

    // TODO: Change test parameters as necessary
    parameter NUM_TESTS = 1000;

    // TODO: Set any necessary model parameters here
    parameter INPUT_LAYER_HEIGHT = 64; // 60 samples, 2 '0' elements on either side
    parameter OUTPUT_LAYER_HEIGHT = 10;
    parameter WORD_SIZE = 16;
    parameter INT_BITS = 4;

    // control variables
    logic clk_i, reset_i, start_i;
    
    // input handshake
    logic [INPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] data_i;
    logic valid_i, ready_o;

    // output handshake
    logic valid_o, yumi_i;
    logic [OUTPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] data_o;

    // values for testing
    logic [NUM_TESTS-1:0] test_inputs [INPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0];
    logic [NUM_TESTS-1:0] expected_outputs [OUTPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0];
    logic [OUTPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] current_expected_output;
    
    // fc output layer and single fifo model the async FIFO that the FPGA will be writing to
    logic [WORD_SIZE-1:0] serial_out, fifo_out;
    logic full, empty, wen, ren;

    fc_output_layer #(
        .LAYER_HEIGHT(INPUT_LAYER_HEIGHT),
        .WORD_SIZE(WORD_SIZE) 
    ) input_serializer (
        .clk_i,
        .reset_i,
    
        // helpful handshake to prev layer
        .valid_i,
        .ready_o,
        .data_i,

        // demanding handshake to next layer
        .wen_o(wen),
        .full_i(full),
        .data_o(serial_out)
    );

    single_fifo #(
        .WORD_SIZE(WORD_SIZE)
    ) input_fifo (
        .clk_i,
        .reset_i,

        .wen_i(wen),
        .data_i(serial_out),
        .empty_o(empty),

        .ren_i(ren),
        .data_o(fifo_out),
        .full_o(full)
    );

    zyNet #(
        .WORD_SIZE(WORD_SIZE),
        .INT_BITS(INT_BITS)
    ) DUT (
        .clk_i,
        .reset_i,

        .start_i,

        .data_i(fifo_out),
        .ready_o(ren),
        .valid_i(!empty),

        .data_o,
        .valid_o,
        .yumi_i
    );
    
    initial begin
        clk_i = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk_i = ~clk_i;
    end

    // read memory files into arrays
    initial begin
        $readmemh("test_inputs.mif", test_inputs);
        $readmemh("test_outputs_expected.mif", expected_outputs);
    end

    // testbench loop
    initial begin
        measured_outputs = $fopen("./mem/test_values/test_outputs_actual.csv", "w");
        errors = $fopen("./mem/test_values/test_output_error.csv", "w");
        reset_i <= 1'b1;
        start_i <= 1'b0;
        yumi_i <= 1'b0;     @(posedge clk_i);
        reset_i <= 1'b0;    @(posedge clk_i);
        for (int i = 0; i < NUM_TESTS; i++) begin
            current_expected_output <= expected_outputs[i];
            data_i <= test_inputs[i];   @(posedge clk_i);
            valid_i <= 1'b1;            @(posedge clk_i);
            valid_i <= 1'b0;            @(posedge clk_i);
            start_i <= 1'b1;            @(posedge clk_i);
            start_i <= 1'b0;            @(posedge clk_i);
                                        @(posedge valid_o);
                                        @(posedge clk_i);
            $fdisplay(measured_outputs, "%d,%h", i, data_o);
            $fdisplay(errors, "%d,%h", i, data_o - current_expected_output);
            yumi_i <= 1'b1;             @(posedge clk_i);
            yumi_i <= 1'b0;             @(posedge clk_i);
        end

        $fclose(measured_outputs);
        $fclose(errors);

        $stop;
    end

endmodule