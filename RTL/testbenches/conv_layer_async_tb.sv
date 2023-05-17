`timescale 1ns / 10ps
`ifndef SYNOPSIS
`define VIVADO
`endif

module conv_layer_tb ();

    localparam WORD_SIZE = 16;
    localparam N_SIZE = 0;
    localparam N_TESTS = 2;
    parameter INPUT_LAYER_HEIGHT = 5;
    parameter KERNEL_HEIGHT = 3;
    parameter KERNEL_WIDTH = 2;
    parameter LAYER_NUMBER = 1;
    parameter N_CONVOLUTIONS = 1;


    // VCS (not Vivado) good stress-test of 1 convolution write port
    `ifndef VIVADO
    logic [$clog2(N_CONVOLUTIONS+1)+$clog2(KERNEL_HEIGHT*KERNEL_WIDTH+1)-1:0] mem_addr_i;
    logic wen_i;
    logic [WORD_SIZE-1:0] mem_data_i;
    `endif

    // demanding input interface
    logic valid_i, yumi_o;
    logic signed [WORD_SIZE-1:0] data_i;
    
    // demanding output interface
    logic valid_o, ready_i;
    // no packed arrays as IO, or they will get screwed up in synthesis
    logic [(N_CONVOLUTIONS*WORD_SIZE)-1:0] data_o;

    assign valid_i = !not_valid_i;

    //// GENERATE CLOCK ////
    parameter CLOCK_PERIOD = 40;
    
    initial begin
        clk_i = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk_i = ~clk_i;
    end

    //// TESTING VALUES ////

    /** 
    Test Kernel:
        [[1 6]
         [1 5]
         [2 3]]

    Test Bias: x0f (15 in decimal)
    2 Test cases:
    
    Test Case 1 input:
        [[1 0]
         [1 5]
         [3 2]
         [9 5]
         [0 1]]

        Expected output:
        43_5c_36

    Test Case 2 input:
        [[4 3]
         [3 1]
         [1 2]
         [f f]
         [5 6]] // try to trigger an overflow
        
        Expected output: overflow on node 1 which comes down because of bias, fine on node 0
        74_6e_34
    */

    logic [N_TESTS-1:0][INPUT_LAYER_HEIGHT-KERNEL_HEIGHT:0][WORD_SIZE-1:0]   expected_outputs;
    logic [N_TESTS-1:0][INPUT_LAYER_HEIGHT*KERNEL_WIDTH-1:0][WORD_SIZE-1:0]  test_inputs;
    logic [KERNEL_HEIGHT*KERNEL_WIDTH:0][WORD_SIZE-1:0]                      kernel_values;

    assign expected_outputs = 96'h0092_006e_0035__0043_005c_0036;
    assign test_inputs[0] = 160'h0001_0000_0005_0009_0002_0003_0005_0001_0000_0001;
    assign test_inputs[1] = 160'h0006_0005_000f_000f_0002_0001_0001_0003_0003_0004;

    `ifndef VIVADO
    initial begin
        $readmemh("../../../mem/0_1_00.mem", kernel_values);
    end
    `endif
    //// TESTING TASKS ////
    
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

    //// GENERATE DUT ////
    conv_layer #(
        .INPUT_LAYER_HEIGHT(INPUT_LAYER_HEIGHT),
        .KERNEL_HEIGHT(KERNEL_HEIGHT),
        .KERNEL_WIDTH(KERNEL_WIDTH),
        .WORD_SIZE(WORD_SIZE),
        .N_SIZE(N_SIZE),
        .LAYER_NUMBER(LAYER_NUMBER),
        .N_CONVOLUTIONS(N_CONVOLUTIONS)
    ) DUT (
        .clk_i,
        .reset_i,
    
        // still need start signal
        .start_i,

        // demanding input interface
        .valid_i,
        .yumi_o,
        .data_i,
    
        // demanding output interface
        .valid_o,
        .ready_i,
        .data_o
    );


    initial begin
        fcin_valid_i <= 1'b0;
        ready_i <= 1'b0;
        start_i <= 1'b0;
        reset_i <= 1'b1;    @(posedge clk_i);
        reset_i <= 1'b0;    @(posedge clk_i);
        
        // if running in VCS, need to write kernel values to memory
        `ifndef VIVADO
        for (int i = 0; i < KERNEL_HEIGHT*KERNEL_WIDTH+1; i++) begin
            $display("Writing %h to address %h", kernel_values[i], i);
            write_mem(kernel_values[i], 1, i);
        end
        `endif
        for (int j = 0; j < N_TESTS; j++) begin
            // assert start
            start_i <= 1'b1; @(posedge clk_i);
            start_i <= 1'b0; @(posedge clk_i);
            // send and receive data, with one delay cycle in between
            for (int k = 0; k < )
        end
        repeat(2) @(posedge clk_i);
        $stop;
    end

endmodule