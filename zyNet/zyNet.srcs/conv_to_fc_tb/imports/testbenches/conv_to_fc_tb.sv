`timescale 1ns / 1ps
`ifndef SYNOPSIS
`define VIVADO
`endif
/**
Alex Knowlton
4/10/2023

Testbench for combining convolutional and fully-connected layers, with no activation function. Serves to prove:
1. parametrized ROM works for small cases, including address of 2 bits
2. fixed-point logic is functional
3. handshakes between layers works for arbitrary layer size
4. all that is needed to build a convolutional neural net is to set layer parameters correctly
   and have the right .mif files in the project
Using 16-bit fixed-point, 2 fraction bits

Layer sizes:
    Convolutional: 2 outputs
    Fully-connected:
        layer of 2 -> layer of 4

Test kernel:
[[ 1   -1.5]
 [ 2   -2]
 [-1.5  1]]

Test Biases:
    Convolutional: x000f (3.75 in decimal)
    Fully-connected 1: xfffe (-0.5 in decimal)
    Fully-connected 2: x0002 (0.5 in decimal)

Test Weights (written as matrix. Right side is LSB, bottom is least significant neuron):
    Layer 1:
        [[ 1.0  1.5  -0.5]
         [-0.5 -0.5   2  ]] <- example, these are weights 2, 1, and 0, respectively, for neuron 0

    Layer 2:
        [[ 2     1]
         [ 1     1]
         [-1    -1]
         [ 0.5   0]]

Test Data 1:
    [[-1     2.5]
     [ 2     0.5]
     [ 3.5  -1.5]
     [ 0.5  -0.5]
     [-1.5   1.5]]
     
Test Data 1 Layer Inputs:
    Convolutional Layer:        48'h003d_0037_ffed, or [[15.25], [13.75], [-4.75]]
    Fully-connected Layer 1:    
    Fully-connected Layer 2: 

Test Data 2:
    [[ 0.25  5]
     [ 1    -2.5]
     [-3.5   1.75]
     [ 0.5   0.25]
     [ 0     1.25]]

Test Data 2 Layer Inputs:
    Convolutional Layer:        48'hfffc_000c_0001, or [[-0.5], [3], [0.25]]
    
Expected Outputs:
Test Data 1:
    64'h0035_fffa_0006_001d, or [13.25, -1.5, 1.5, 7.25]
    
Test Data 2:
    64'h001b_000c_fff4_0007, or [[6.75], [3], [-3], [1.75]]
*/

module conv_to_fc_tb ();

    // model parameters
    localparam INPUT_LAYER_HEIGHT = 5;
    localparam KERNEL_WIDTH = 2;
    localparam KERNEL_HEIGHT = 3;
    localparam N_SIZE = 2;
    localparam WORD_SIZE = 16;
    localparam HIDDEN_LAYER_HEIGHT = 2;
    localparam OUTPUT_LAYER_HEIGHT = 4;
    
    // simulation parameters
    localparam N_TESTS = 2;
    
    logic [N_TESTS-1:0][OUTPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0]   expected_outputs;
    logic [N_TESTS-1:0][INPUT_LAYER_HEIGHT*KERNEL_WIDTH-1:0][WORD_SIZE-1:0]  test_inputs;
    logic [KERNEL_HEIGHT*KERNEL_WIDTH:0][WORD_SIZE-1:0]                      kernel_values;
    logic [HIDDEN_LAYER_HEIGHT-1:0][INPUT_LAYER_HEIGHT-KERNEL_HEIGHT:0][WORD_SIZE-1:0] hidden_layer_values;
    logic [OUTPUT_LAYER_HEIGHT-1:0][HIDDEN_LAYER_HEIGHT-1:0][WORD_SIZE-1:0]  output_layer_values;

    assign expected_outputs = 128'h0008_0031_ffd3_ffed__00ce_0037_ffcd_004d;
    assign test_inputs[0] = 160'h0006_fffa_fffe_0002_fffa_000e_0002_0008_000a_fffc;
    assign test_inputs[1] = 160'h0005_0000_0001_0002_0007_fff2_fff6_0004_0014_0001;

    `ifndef VIVADO
    // if using VCS, need to read in the mem files to kernel_values for writing to memory
    initial begin
        $readmemh("../../../mem/test_mem_files/0_6_000.mem", kernel_values);
        $readmemh("../../../mem/test_mem_files/1_7_000.mem", hidden_layer_values[0]);
        $readmemh("../../../mem/test_mem_files/1_7_001.mem", hidden_layer_values[1]);
        $readmemh("../../../mem/test_mem_files/1_8_000.mem", output_layer_values[0]);
        $readmemh("../../../mem/test_mem_files/1_8_001.mem", output_layer_values[1]);
        $readmemh("../../../mem/test_mem_files/1_8_002.mem", output_layer_values[2]);
        $readmemh("../../../mem/test_mem_files/1_8_003.mem", output_layer_values[3]);
    end
    `endif
    //// TESTING TASKS ////
    
    //// DEFINE INPUT/OUTPUT VARIABLES ////
    logic [INPUT_LAYER_HEIGHT*KERNEL_WIDTH-1:0][WORD_SIZE-1:0] input_layer_data;
    logic [WORD_SIZE-1:0] input_fifo_data, conv_layer_data, hidden_layer_input_data;
    logic [HIDDEN_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] hidden_layer_output_data;
    logic [WORD_SIZE-1:0] output_layer_input_data;
    logic [OUTPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] output_layer_output_data;
    
    // control signals
    logic clk_i, reset_i, start_i, conv_ready_o;
    
    // input layer input handshake
    logic fcin_ready_o, fcin_valid_i;
    
    // input layer output handshake
    logic fcin_valid_o, fcin_yumi_i, not_fcin_yumi_i;
    assign fcin_yumi_i = !not_fcin_yumi_i;

    // convolutional layer input handshake (demanding)
    logic conv_layer_yumi_o, conv_layer_valid_i, not_conv_layer_valid_i;
    assign conv_layer_valid_i = not_conv_layer_valid_i;
    
    // hidden layer input handshake
    logic hidden_layer_valid_i, hidden_layer_ready_o;
    
    // hidden layer piso layer handshake
    logic hidden_layer_piso_valid_i, hidden_layer_piso_ready_o;
    
    // output layer input handshake
    logic output_layer_valid_i, output_layer_ready_o;
    
    // output layer output handshake
    logic output_layer_valid_o, output_layer_yumi_i;

    fc_output_layer #(
        .LAYER_HEIGHT(INPUT_LAYER_HEIGHT*KERNEL_WIDTH),
        .WORD_SIZE(WORD_SIZE)
    ) input_layer (
        .clk_i,
        .reset_i,

        // helpful handshake to prev layer
        .valid_i(fcin_valid_i),
        .ready_o(fcin_ready_o),
        .data_i(input_layer_data),

        .yumi_i(fcin_yumi_i),
        .valid_o(fcin_valid_o),
        .data_o(input_fifo_data)
    );

    single_fifo_no_rw #(
        .WORD_SIZE(WORD_SIZE)
    ) input_fifo (
        .clk_i,
        .reset_i,

        .wen_i(fcin_valid_o),
        .data_i(input_fifo_data),
        .empty_o(not_fcin_yumi_i),

        .ren_i(conv_layer_yumi_o),
        .data_o(conv_layer_data),
        .full_o(not_conv_layer_valid_i)
    );

    conv_layer #(
        .INPUT_LAYER_HEIGHT(INPUT_LAYER_HEIGHT),
        .KERNEL_HEIGHT(KERNEL_HEIGHT),
        .KERNEL_WIDTH(KERNEL_WIDTH),
        .WORD_SIZE(WORD_SIZE),
        .N_SIZE(N_SIZE),
        .LAYER_NUMBER(6),
        .N_CONVOLUTIONS(1)
    ) convolution (
        // top-level signals
        .clk_i,
        .reset_i,

        .start_i,
        .conv_ready_o,

        // demanding input interface
        .valid_i(conv_layer_valid_i),
        .yumi_o(conv_layer_yumi_o),
        .data_i(conv_layer_data),

        // demanding output interface
        .valid_o(hidden_layer_valid_i),
        .ready_i(hidden_layer_ready_o),
        .data_o(hidden_layer_input_data)
    );

    fc_layer #(
        .WORD_SIZE(WORD_SIZE),
        .N_SIZE(N_SIZE),
        .LAYER_HEIGHT(HIDDEN_LAYER_HEIGHT),
        .PREVIOUS_LAYER_HEIGHT(INPUT_LAYER_HEIGHT-KERNEL_HEIGHT+1),
        .LAYER_NUMBER(7)
    ) hidden_layer (
        // helpful
        .data_i(hidden_layer_input_data),
        .valid_i(hidden_layer_valid_i),
        .ready_o(hidden_layer_ready_o),

        // helpful output interface
        .valid_o(hidden_layer_piso_valid_i),
        .yumi_i(hidden_layer_piso_ready_o),
        .data_o(hidden_layer_output_data),

        .reset_i,
        .clk_i
    );

    fc_output_layer #(
        .LAYER_HEIGHT(HIDDEN_LAYER_HEIGHT),
        .WORD_SIZE(WORD_SIZE)
    ) hidden_layer_output (
        .clk_i,
        .reset_i,

        // helpful handshake to prev layer
        .valid_i(hidden_layer_piso_valid_i),
        .ready_o(hidden_layer_piso_ready_o),
        .data_i(hidden_layer_output_data),

        // demanding handshake to next layer
        .valid_o(output_layer_valid_i),
        .yumi_i(output_layer_ready_o),
        .data_o(output_layer_input_data)
    );

    fc_layer #(

        .WORD_SIZE(WORD_SIZE),
        .N_SIZE(N_SIZE),
        .LAYER_HEIGHT(OUTPUT_LAYER_HEIGHT),
        .PREVIOUS_LAYER_HEIGHT(HIDDEN_LAYER_HEIGHT),
        .LAYER_NUMBER(8)
    ) output_layer (
        // helpful
        .data_i(output_layer_input_data),
        .valid_i(output_layer_valid_i),
        .ready_o(output_layer_ready_o),

        // helpful output interface
        .valid_o(output_layer_valid_o),
        .yumi_i(output_layer_yumi_i),
        .data_o(output_layer_output_data),

        .reset_i,
        .clk_i
    );
    
    //// GENERATE CLOCK ////
    parameter CLOCK_PERIOD = 40;
    
    initial begin
        clk_i = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk_i = ~clk_i;
    end
    
    // RUN TESTBENCH
    initial begin
        start_i <= 1'b0;
        output_layer_yumi_i <= 1'b0;
        fcin_valid_i <= 1'b0;
        reset_i <= 1'b1;        @(posedge clk_i);
        reset_i <= 1'b0;        @(posedge clk_i);
        start_i <= 1'b1;        @(posedge clk_i);
        start_i <= 1'b0;        @(posedge clk_i);
        
        // test case 1
        input_layer_data <= test_inputs[0];
        fcin_valid_i <= 1'b1;   @(posedge clk_i);
        fcin_valid_i <= 1'b0;   @(posedge clk_i);
                                @(posedge output_layer_valid_o);
                                @(negedge clk_i);
        $display("%t: Asserting Test Case 1", $realtime);
        assert (output_layer_output_data == expected_outputs[0])
            $display("%t: Test Case 1 Passed", $realtime);    
        else
            $display("%t: Assertion Error: Expected %h, Received %h", $realtime, expected_outputs[0], output_layer_output_data);
        output_layer_yumi_i <= 1'b1; @(posedge clk_i);
        output_layer_yumi_i <= 1'b0; @(posedge clk_i);
        
        // test case 2
        start_i <= 1'b1;        @(posedge clk_i);
        start_i <= 1'b0;        @(posedge clk_i);
        input_layer_data <= test_inputs[1];
        fcin_valid_i <= 1'b1;   @(posedge clk_i);
        fcin_valid_i <= 1'b0;   @(posedge clk_i);
                                @(posedge output_layer_valid_o);
                                @(negedge clk_i);
        $display("%t: Asserting Test Case 2", $realtime);
        assert (output_layer_output_data == expected_outputs[1])
            $display("%t: Test Case 2 Passed", $realtime); 
        else
            $display("%t: Assertion Error: Expected %h, Received %h", $realtime, expected_outputs[1], output_layer_output_data);
        output_layer_yumi_i <= 1'b1; @(posedge clk_i);
        output_layer_yumi_i <= 1'b0; @(posedge clk_i);
        
        $stop;
    end

endmodule