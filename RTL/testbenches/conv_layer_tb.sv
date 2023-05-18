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

    //// INPUT LAYER VALUES ////
    // helpful handshake to prev layer
    logic fcin_valid_i, fcin_ready_o;
    logic [INPUT_LAYER_HEIGHT*KERNEL_WIDTH-1:0][WORD_SIZE-1:0] fcin_data_i;

    // demanding handshake to next layer
    logic fcin_wen_o, fcin_full_i;
    logic [WORD_SIZE-1:0] fcin_data_o;

    logic not_valid_i;

    //// DUT VALUES ////
    logic clk_i, reset_i, start_i, conv_ready_o;
    
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
        $readmemh("../../../mem/0_5_00.mem", kernel_values);
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

    task send_data(input logic [INPUT_LAYER_HEIGHT*KERNEL_WIDTH-1:0][WORD_SIZE-1:0] data);
        $display("%t: Sending %x to input layer", $realtime, data);
        @(negedge clk_i)
        fcin_valid_i <= 1'b1;
        fcin_data_i <= data;
        
        @(posedge clk_i)
        fcin_valid_i <= 1'b0;
        fcin_data_o <= 'x;
    endtask

    task receive_data(input logic [WORD_SIZE-1:0] expected_value);
        $display("%t: Receiving data: Expecting %h, Received %h", $realtime, expected_value, data_o);
        assert(expected_value == data_o)
            else $display("%t: Assertion Error: Expected %h, Received %h", $realtime, expected_value, data_o);
    endtask

    //// GENERATE DEVICES ////
    fc_output_layer #(
        .LAYER_HEIGHT(INPUT_LAYER_HEIGHT*KERNEL_WIDTH),
        .WORD_SIZE(WORD_SIZE)
    ) input_layer (
        .clk_i,
        .reset_i,
        .valid_i(fcin_valid_i),
        .ready_o(fcin_ready_o),
        .data_i(fcin_data_i),
        
        .valid_o(fcin_wen_o),
        .yumi_i(!fcin_full_i),
        .data_o(fcin_data_o)
    );

    single_fifo_no_rw #(
        .WORD_SIZE(WORD_SIZE)
    ) input_fifo (
        .clk_i,
        .reset_i,

        .wen_i(fcin_wen_o),
        .data_i(fcin_data_o),
        .full_o(fcin_full_i),

        .ren_i(yumi_o),
        .empty_o(not_valid_i), // this may not work
        .data_o(data_i)
    );

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
            repeat(2) @(posedge clk_i);
            start_i <= 1'b1; @(posedge clk_i);
            start_i <= 1'b0; @(posedge clk_i);
            send_data(test_inputs[j]);
            repeat(4) @(posedge clk_i);
            ready_i <= 1'b1;    @(posedge clk_i);
            @(posedge valid_o);
            for (int i = 0; i < INPUT_LAYER_HEIGHT - KERNEL_HEIGHT + 1; i ++) begin
                @(posedge valid_o);
                receive_data(expected_outputs[j][i]);
            end
        end
        repeat(2) @(posedge clk_i);
        $stop;
    end

endmodule