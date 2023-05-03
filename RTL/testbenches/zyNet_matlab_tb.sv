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
    parameter NUM_TESTS = 7176;

    // TODO: Set any necessary model parameters here
    parameter INPUT_LAYER_HEIGHT = 256; // 60 samples, 2 '0' elements on either side  256 32
    parameter OUTPUT_LAYER_HEIGHT = 10;
    parameter WORD_SIZE = 16;
    parameter INT_BITS = 4;
    
    
    parameter CLOCK_PERIOD = 2;

    // control variables
    logic clk_i, reset_i, start_i;
    
    // input handshake
    logic [INPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] data_i;
    logic valid_i, ready_o;

    // output handshake
    logic valid_o, yumi_i;
    logic [OUTPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] data_o;

    // values for testing
    logic [INPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] test_inputs [NUM_TESTS-1:0];
    logic [OUTPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] expected_outputs [NUM_TESTS-1:0];
    logic [OUTPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] current_expected_output ;
    
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
        .full_o(full),
        .data_i(serial_out),

        
        .ren_i(ren),
        .data_o(fifo_out),
        .empty_o(empty)
    );

    zyNet #(
        .WORD_SIZE(WORD_SIZE),
        .INT_BITS(INT_BITS),
        .OUTPUT_SIZE(OUTPUT_LAYER_HEIGHT)
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

//    // read memory files into arrays
//    initial begin
//        $readmemh("test_inputs.mif", test_inputs);
//        $readmemh("test_outputs_expected.mif", expected_outputs);
//    end

    // testbench loop
    int measured_outputs, errors;
    initial begin
        $readmemh("test_inputs.mif", test_inputs);
        $readmemh("test_outputs_expected.mif", expected_outputs);
        measured_outputs = $fopen("C:/Users/eugli/Documents/GitHub/fir-cnn-rtl/mem/test_values/test_outputs_actual.csv", "w");
        errors = $fopen("C:/Users/eugli/Documents/GitHub/fir-cnn-rtl/mem/test_values/test_output_error.csv", "w");
        reset_i <= 1'b1;
        start_i <= 1'b0;
        yumi_i <= 1'b0;     @(posedge clk_i); @(posedge clk_i);
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
                                        
            for (int j = 0; j < OUTPUT_LAYER_HEIGHT-1; j++) begin
                $fwrite(measured_outputs, "%h,", data_o[j]);
                $fwrite(errors, "%f,", $itor(data_o[j])/(2.0**WORD_SIZE-INT_BITS) - $itor(current_expected_output[j])/(2.0**WORD_SIZE-INT_BITS));
            end
            $fwrite(measured_outputs, "%h\n", data_o[OUTPUT_LAYER_HEIGHT-1]);
            $fwrite(errors, "%f\n", $itor(data_o[OUTPUT_LAYER_HEIGHT-1])/(2.0**WORD_SIZE-INT_BITS) - $itor(current_expected_output[OUTPUT_LAYER_HEIGHT-1])/(2.0**WORD_SIZE-INT_BITS));
            
            yumi_i <= 1'b1;             @(posedge clk_i);
            yumi_i <= 1'b0;             @(posedge clk_i);
        end

        $fclose(measured_outputs);
        $fclose(errors);

        $stop;
    end

endmodule