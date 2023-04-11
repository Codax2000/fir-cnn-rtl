`timescale 1ns / 1ps
/**
Alex Knowlton
4/10/2023

Testbench for combining convolutional and fully-connected layers, with no activation function. Serves to prove:
1. parametrized ROM works for small cases, including address of 2 bits
2. fixed-point logic is functional
3. handshakes between layers works for arbitrary layer size
4. all that is needed to build a convolutional neural net is to set layer parameters correctly
   and have the right .mif files in the project
Using 8-bit fixed-point, 6 integer bits

Layer sizes:
    Convolutional: 2 outputs
    Fully-connected:
        layer of 2 -> layer of 4

Test kernel:
[[ 1   -1.5]
 [ 2   -2]
 [-1.5  1]]

Test Biases:
    Convolutional: xfc (-1 in decimal)
    Fully-connected 1: xfe (-0.5 in decimal)
    Fully-connected 2: x02 (0.5 in decimal)

Test Weights (written as matrix. Right side is LSB, bottom is least significant neuron):
    Layer 1:
        [[ 1.5  -0.5]
         [-0.5   2  ]] <- example, these are weights 1 and 0, respectively, for neuron 0

    Layer 2:
        [[ 2     1]
         [ 1     1]
         [-1    -1]
         [ 0.5   0]]

Test Data 1:
    [[-1     2.5]
     [ 2     0.5]
     [ 3.5  -1.5]
     [ 0.5  -0.5]]

Test Data 2: Trigger an overflow somewhere on the line
    [[ 0.25  5]
     [ 1    -2.5]
     [-3.5   1.75]
     [ 0.5   0.25]]

Expected Outputs:
Test Data 1:
    00_e3_21_10

*/

module conv_to_fc_tb ();

    // parameters for layer sizes
    parameter WORD_SIZE = 8;
    parameter INT_BITS = 6;
    parameter INPUT_LAYER_HEIGHT = 4;
    parameter KERNEL_HEIGHT = 3;
    parameter KERNEL_WIDTH = 2;
    parameter HIDDEN_LAYER_HEIGHT = 2;
    parameter OUTPUT_LAYER_HEIGHT = 4;

    logic clk_i, reset_i;

    // intermediate data buses
    logic [WORD_SIZE-1:0] input_data;
    logic [INPUT_LAYER_HEIGHT-KERNEL_HEIGHT:0][WORD_SIZE-1:0] convolution_data;
    logic [HIDDEN_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] hidden_layer_data;
    logic [OUTPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] output_layer_data;
    logic [WORD_SIZE-1:0] conv_fifo_in, hidden_layer_in, hidden_fifo_in, output_layer_in, output_fifo_in;
    logic [WORD_SIZE-1:0] data_out;

    // handshake signals, controlled by simulation
    logic start_i, ren_out;

    // handshake signals, controlled by modules
    logic conv_valid, conv_out_ready;
    logic conv_fifo_wen, conv_fifo_full;
    logic hidden_layer_ren, hidden_layer_empty;
    logic hidden_layer_valid, hidden_layer_ready;
    logic hidden_fifo_full, hidden_fifo_wen;
    logic hidden_fifo_ren, hidden_fifo_empty;
    logic output_layer_ready, output_layer_valid;
    logic output_fifo_full, output_fifo_wen;
    logic output_fifo_empty; // watch for this signal to assert 0 is testbench, gives output data

    // generate clock
    parameter CLOCK_PERIOD = 100;

    initial begin
        clk_i = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk_i = ~clk_i;
    end

    // generate devices under test
    conv_layer #(
        .INPUT_LAYER_HEIGHT(INPUT_LAYER_HEIGHT),
        .KERNEL_HEIGHT(KERNEL_HEIGHT),
        .KERNEL_WIDTH(KERNEL_WIDTH), // 2 if using i and q, 1 if using only 1 channel
        .WORD_SIZE(WORD_SIZE),
        .INT_BITS(INT_BITS),
        .LAYER_NUMBER(2),
        .CONVOLUTION_NUMBER(0)
    ) convolution (    
        .clk_i,
        .reset_i,
    
        // input interface
        .start_i,
        .data_i(input_data),
    
        // helpful output interface
        .valid_o(conv_valid),
        .yumi_i(conv_out_ready),
        .data_o(convolution_data)
    );

    fc_output_layer #(
        .LAYER_HEIGHT(INPUT_LAYER_HEIGHT-KERNEL_HEIGHT+1),
        .WORD_SIZE(WORD_SIZE)
    ) convolution_output (
        .clk_i,
        .reset_i,
    
        .valid_i(conv_valid),
        .ready_o(conv_out_ready),
        .data_i(convolution_data),

        .wen_o(conv_fifo_wen),
        .full_i(conv_fifo_full),
        .data_o(conv_fifo_in)
    );

    double_fifo #(
        .WORD_SIZE(WORD_SIZE)
    ) conv_out_fifo (
        .clk_i,
        .reset_i,
        
        .wen_i(conv_fifo_wen),
        .ren_i(hidden_layer_ren),
        .data_i(conv_fifo_in),

        .full_o(conv_fifo_full),
        .empty_o(hidden_layer_empty),
        .data_o(hidden_layer_in)
    );

    fc_layer #(
        .WORD_SIZE(WORD_SIZE),
        .INT_BITS(INT_BITS),
        .LAYER_HEIGHT(HIDDEN_LAYER_HEIGHT),
        .PREVIOUS_LAYER_HEIGHT(INPUT_LAYER_HEIGHT - KERNEL_HEIGHT + 1),
        .LAYER_NUMBER(3)
    ) layer_1 (
        // helpful input interface
        .data_i(hidden_layer_in),
        .empty_i(hidden_layer_empty),
        .ren_o(hidden_layer_ren),
        
        // helpful output interface
        .valid_o(hidden_layer_valid),
        .ready_i(hidden_layer_ready),
        .data_o(hidden_layer_data),

        .reset_i,
        .clk_i,

        // input for back-propagation, not currently used
        .weight_i('0),
        .mem_wen_i(1'b0)
    );

    fc_output_layer #(
        .LAYER_HEIGHT(HIDDEN_LAYER_HEIGHT),
        .WORD_SIZE(WORD_SIZE)
    ) hidden_layer_output (
        .clk_i,
        .reset_i,
    
        .valid_i(hidden_layer_valid),
        .ready_o(hidden_layer_ready),
        .data_i(hidden_layer_data),

        .wen_o(hidden_fifo_wen),
        .full_i(hidden_fifo_full),
        .data_o(hidden_fifo_in)
    );

    double_fifo #(
        .WORD_SIZE(WORD_SIZE)
    ) hidden_out_fifo (
        .clk_i,
        .reset_i,
        
        .wen_i(hidden_fifo_wen),
        .ren_i(hidden_fifo_ren),
        .data_i(hidden_fifo_in),

        .full_o(hidden_fifo_full),
        .empty_o(hidden_fifo_empty),
        .data_o(output_layer_in)
    );

    fc_layer #(
        .WORD_SIZE(WORD_SIZE),
        .INT_BITS(INT_BITS),
        .LAYER_HEIGHT(OUTPUT_LAYER_HEIGHT),
        .PREVIOUS_LAYER_HEIGHT(HIDDEN_LAYER_HEIGHT),
        .LAYER_NUMBER(4)
    ) layer_2 (
        // helpful input interface
        .data_i(output_layer_in),
        .empty_i(hidden_fifo_empty),
        .ren_o(hidden_fifo_ren),
        
        // helpful output interface
        .valid_o(output_layer_valid),
        .ready_i(output_layer_ready),
        .data_o(output_layer_data),

        .reset_i,
        .clk_i,

        // input for back-propagation, not currently used
        .weight_i('0),
        .mem_wen_i(1'b0)
    );


    fc_output_layer #(
        .LAYER_HEIGHT(OUTPUT_LAYER_HEIGHT),
        .WORD_SIZE(WORD_SIZE)
    ) output_layer_output (
        .clk_i,
        .reset_i,
    
        .valid_i(output_layer_valid),
        .ready_o(output_layer_ready),
        .data_i(output_layer_data),

        .wen_o(output_fifo_wen),
        .full_i(output_fifo_full),
        .data_o(output_fifo_in)
    );

    double_fifo #(
        .WORD_SIZE(WORD_SIZE)
    ) output_fifo (
        .clk_i,
        .reset_i,
        
        .wen_i(output_fifo_wen),
        .ren_i(ren_out),
        .data_i(output_fifo_in),

        .full_o(output_fifo_full),
        .empty_o(output_fifo_empty),
        .data_o(data_out)
    );

    initial begin
        start_i <= 1'b0;
        ren_out <= 1'b0;
        input_data <= '0;
        reset_i <= 1'b1; @(posedge clk_i);
        reset_i <= 1'b0; @(posedge clk_i);
        input_data <= 8'hfc; @(posedge clk_i);
        input_data <= 8'h0a; @(posedge clk_i);
        input_data <= 8'h08; @(posedge clk_i);
        input_data <= 8'h02; @(posedge clk_i);
        input_data <= 8'h0e; @(posedge clk_i);
        start_i <= 1'b1;    
        input_data <= 8'h06; @(posedge clk_i);
        start_i <= 1'b0;
        input_data <= 8'h02; @(posedge clk_i);
        input_data <= 8'hfe; @(posedge clk_i);
        input_data <= '0;    @(posedge clk_i);
                         @(negedge output_fifo_empty);
                         @(posedge clk_i);
        assert (data_out == 8'h10)
            else $display("Assertion Error 1: Expected %h, Received %h", 8'h10, data_out);
        ren_out <= 1'b1; @(posedge clk_i);
        ren_out <= 1'b0; @(posedge clk_i);
        assert (data_out == 8'h21)
            else $display("Assertion Error 2: Expected %h, Received %h", 8'h21, data_out);
        ren_out <= 1'b1; @(posedge clk_i);
        ren_out <= 1'b0; @(posedge clk_i);
        assert (data_out == 8'he3)
            else $display("Assertion Error 3: Expected %h, Received %h", 8'he3, data_out);
        ren_out <= 1'b1; @(posedge clk_i);
        ren_out <= 1'b0; @(posedge clk_i);
        assert (data_out == 8'h00)
            else $display("Assertion Error 4: Expected %h, Received %h", 8'h0, data_out);
        ren_out <= 1'b1; @(posedge clk_i);
        ren_out <= 1'b0; @(posedge clk_i);
        assert (!output_fifo_empty)
            else $display("Assertion Error 5: Output FIFO Should be Empty");
        repeat(2)        @(posedge clk_i);
        $stop;
    end

endmodule