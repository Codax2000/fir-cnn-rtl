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
    Convolutional Layer:        48'h0041_fff6_ffed, or [[16.25], [-2.5], [-4.75]]
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
    
    logic [N_TESTS-1:0][INPUT_LAYER_HEIGHT-KERNEL_HEIGHT:0][WORD_SIZE-1:0]   expected_outputs;
    logic [N_TESTS-1:0][INPUT_LAYER_HEIGHT*KERNEL_WIDTH-1:0][WORD_SIZE-1:0]  test_inputs;
    logic [KERNEL_HEIGHT*KERNEL_WIDTH:0][WORD_SIZE-1:0]                      kernel_values;
    logic [HIDDEN_LAYER_HEIGHT-1:0][INPUT_LAYER_HEIGHT-KERNEL_HEIGHT:0][WORD_SIZE-1:0] hidden_layer_values;
    logic [OUTPUT_LAYER_HEIGHT-1:0][HIDDEN_LAYER_HEIGHT-1:0][WORD_SIZE-1:0]  output_layer_values;

    assign expected_outputs = 128'h001b_000c_fff4_0007__0035_fffa_0006_001d;
    assign test_inputs[0] = 160'hfffc_000a_0008_0002_000e_fffa_0002_fffe_fffa_0006;
    assign test_inputs[1] = 160'h0001_0014_0004_fff6_fff2_0007_0002_0001_0000_0005;

    `ifndef VIVADO
    // if using VCS, need to read in the mem files to kernel_values for writing to memory
    initial begin
        $readmemh("../../../mem/0_6_000.mem", kernel_values);
        $readmemh("../../../mem/1_7_000.mem", hidden_layer_values[0]);
        $readmemh("../../../mem/1_7_001.mem", hidden_layer_values[1]);
        $readmemh("../../../mem/1_8_000.mem", output_layer_values[0]);
        $readmemh("../../../mem/1_8_001.mem", output_layer_values[1]);
        $readmemh("../../../mem/1_8_002.mem", output_layer_values[2]);
        $readmemh("../../../mem/1_8_003.mem", output_layer_values[3]);
    end
    `endif
    //// TESTING TASKS ////
    
    //// DEFINE INPUT/OUTPUT VARIABLES ////
    logic [INPUT_LAYER_HEIGHT*KERNEL_WIDTH-1:0][WORD_SIZE-1:0] input_layer_data;
    logic [WORD_SIZE-1:0] conv_layer_data, hidden_layer_input_data;
    logic [HIDDEN_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] hidden_layer_output_data;
    logic [WORD_SIZE-1:0] output_layer_input_data;
    logic [OUTPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] output_layer_output_data;
    
    // input layer input handshake
    logic fcin_ready_o, fcin_valid_i;
    
    // convolutional layer input handshake (demanding)
    logic conv_layer_yumi_o, conv_layer_valid_i;
    
    // hidden layer input handshake
    logic hidden_layer_valid_i, hidden_layer_ready_o;
    
    // hidden layer piso layer handshake
    logic hidden_layer_piso_valid_i, hidden_layer_ready_o;
    
    // output layer input handshake
    logic output_layer_valid_i, output_layer_ready_o;
    
    // output layer output handshake
    logic output_layer_valid_o, output_layer_yumi_i;
    
    
    // write to memory address
    `ifndef VIVADO
    task write_mem(input logic [WORD_SIZE-1:0] data,
                   input logic [$clog2(N_CONVOLUTIONS+1)-1:0] mem_index,
                   input logic [$clog2(KERNEL_HEIGHT*KERNEL_WIDTH+1)-1:0] mem_addr);
        $display("%t: Writing %x to %x in memory %x", $realtime, data, mem_addr, mem_index);
        @(negedge clk_i)
        mem_addr_i <= {mem_index, mem_addr};
        wen_i <= 1'b1;
        mem_data_i <= data;
        @(posedge clk_i)
        mem_addr_i <= 'x;
        wen_i <= 1'b0;
        mem_data_i <= 'x;
    endtask
    `endif

    task send_data(input logic [INPUT_LAYER_HEIGHT*KERNEL_WIDTH-1:0][WORD_SIZE-1:0] data);
        $display("%t: Sending %x to input layer", $realtime, data);
    endtask

    task receive_data(input logic [WORD_SIZE-1:0] expected_value);
        $display("%t: Receiving data: Expecting %h, Received %h", $realtime, expected_value, data_o);
        assert(expected_value == data_o)
            else $display("%t: Assertion Error: Expected %h, Received %h", $realtime, expected_value, data_o);
    endtask

    fc_output_layer #(
        .LAYER_HEIGHT(),
        .WORD_SIZE()
    ) input_layer (
        .clk_i(),
        .reset_i(),

        // helpful handshake to prev layer
        .valid_i(),
        .ready_o(),
        .data_i(),

        // demanding handshake to next layer
        .wen_o(),
        .full_i(),
        .data_o()
    );

    // generate modules
    conv_layer #(
        `ifndef VIVADO
        .RAM_ADDRESS_BITS(),
        .RAM_SELECT_BITS(),
        `endif
        .INPUT_LAYER_HEIGHT(),
        .KERNEL_HEIGHT(),
        .KERNEL_WIDTH(),
        .WORD_SIZE(),
        .N_SIZE(),
        .LAYER_NUMBER(),
        .N_CONVOLUTIONS()
    ) convolution (
        // top-level signals
        .clk_i(),
        .reset_i(),

        .start_i(),
        .conv_ready_o(),

        `ifndef VIVADO
        .mem_addr_i(),
        .w_en_i(),
        .mem_data_i(),
        `endif

        // demanding input interface
        .valid_i(),
        .yumi_o(),
        .data_i(),

        // demanding output interface
        .valid_o(),
        .ready_i(),
        // no packed arrays as IO, or they will get screwed up in synthesis
        .data_o()
    );

    fc_layer #(

        `ifndef VIVADO
        .RAM_ADDRESS_BITS(),
        .RAM_SELECT_BITS(),
        `endif

        .WORD_SIZE(),
        .N_SIZE(),
        .LAYER_HEIGHT(),
        .PREVIOUS_LAYER_HEIGHT(),
        .LAYER_NUMBER()
    ) hidden_layer (
        // helpful
        .data_i(),
        .valid_i(),
        .ready_o(),

        // helpful output interface
        .valid_o(),
        .yumi_i(),
        .data_o(),

        .reset_i(),
        .clk_i(),

        `ifndef VIVADO
        .mem_addr_i(),
        .w_en_i(),
        .mem_data_i(),
        `endif
    );

    fc_output_layer #(
        .LAYER_HEIGHT(),
        .WORD_SIZE()
    ) hidden_layer_output (
        .clk_i(),
        .reset_i(),

        // helpful handshake to prev layer
        .valid_i(),
        .ready_o(),
        .data_i(),

        // demanding handshake to next layer
        .wen_o(),
        .full_i(),
        .data_o()
    );

    fc_layer #(

        `ifndef VIVADO
        .RAM_ADDRESS_BITS(),
        .RAM_SELECT_BITS(),
        `endif

        .WORD_SIZE(),
        .N_SIZE(),
        .LAYER_HEIGHT(),
        .PREVIOUS_LAYER_HEIGHT(),
        .LAYER_NUMBER()
    ) output_layer (
        // helpful
        .data_i(),
        .valid_i(),
        .ready_o(),

        // helpful output interface
        .valid_o(),
        .yumi_i(),
        .data_o(),

        .reset_i(),
        .clk_i(),

        `ifndef VIVADO
        .mem_addr_i(),
        .w_en_i(),
        .mem_data_i(),
        `endif
    );

endmodule