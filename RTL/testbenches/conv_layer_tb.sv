`timescale 1ns / 1ps

module conv_layer_tb ();

    parameter CLOCK_PERIOD = 100;
    
    parameter INPUT_LAYER_HEIGHT = 4;
    parameter KERNEL_HEIGHT = 3;
    parameter KERNEL_WIDTH = 2;
    parameter WORD_SIZE = 8;
    parameter INT_BITS = 8;

    logic [INPUT_LAYER_HEIGHT*2-1:0][WORD_SIZE-1:0] data_i;
    logic [WORD_SIZE-1:0] fifo_data_in, fifo_data_out;
    logic [INPUT_LAYER_HEIGHT - KERNEL_HEIGHT:0][WORD_SIZE-1:0] data_o;

    logic fifo_full, fifo_empty, wen, ren;

    // signals to control in testbench
    logic valid_i, start_i, yumi_i;
    
    // clock and reset signals
    logic reset_i, clk_i;

    // ready and valid outputs, useful for watching within testbench
    logic ready_o, valid_o;

    fc_output_layer #(
        .LAYER_HEIGHT(INPUT_LAYER_HEIGHT*2),
        .WORD_SIZE(WORD_SIZE)
    ) test_input_serializer (
        .clk_i,
        .reset_i,
    
        .valid_i,
        .ready_o,
        .data_i,

        .wen_o(wen),
        .full_i(fifo_full),
        .data_o(fifo_data_in)
    );

    double_fifo #(
        .WORD_SIZE(WORD_SIZE)
    ) middle_fifo (
        .clk_i,
        .reset_i,

        .wen_i(wen),
        .data_i(fifo_data_in),
        .full_o(fifo_full),
        
        .data_o(fifo_data_out),
        .empty_o(fifo_empty),
        .ren_i(ren)
    );

    conv_layer #(
        .INPUT_LAYER_HEIGHT(INPUT_LAYER_HEIGHT),
        .KERNEL_HEIGHT(KERNEL_HEIGHT),
        .KERNEL_WIDTH(KERNEL_WIDTH),
        .WORD_SIZE(WORD_SIZE),
        .INT_BITS(INT_BITS),
        .LAYER_NUMBER(1),
        .CONVOLUTION_NUMBER(0)
    ) DUT (
        .clk_i,
        .reset_i,
        
        // still need start signal
        .start_i,

        // input interface
        .valid_i(!fifo_empty),
        .ready_o(ren),
        .data_i(fifo_data_out),
        
        // helpful output interface
        .valid_o,
        .yumi_i,
        .data_o
    );
    
    initial begin
        clk_i = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk_i = ~clk_i;
    end

    /** 
    Test Kernel:
        [[1 6]
         [1 5]
         [2 3]]

    Test Bias: x0f (15 in decimal)
    2 Test cases:
    
    Test Case 1 input:
        [[1 5]
         [3 2]
         [9 5]
         [0 1]]

        Expected output:
        43_5c

    Test Case 2 input:
        [[3 1]
         [1 2]
         [f f]
         [5 6]] // try to trigger an overflow
        
        Expected output: overflow on node 1, fine on node 0
        7f_6e
        
    
        data_i <= 64'h06_08_0f_0f_02_01_01_03; // data for test case 2
    */
    initial begin
        reset_i <= 1'b1;    @(posedge clk_i);
        data_i <= 64'h01_00_05_09_02_03_05_01; // data for test case 1
        start_i <= 1'b0;
        yumi_i <= 1'b0;
        valid_i <= 1'b0;
        reset_i <= 1'b0;    @(posedge clk_i);
        valid_i <= 1'b1;    @(posedge clk_i);
        valid_i <= 1'b0;    @(posedge clk_i);
                            @(negedge fifo_empty);
                            @(posedge clk_i);
        start_i <= 1'b1;    @(posedge clk_i);
        start_i <= 1'b0;    @(posedge clk_i);
                            @(posedge valid_o);
        $display("Assert Test Case 1:");
        assert(data_o == 16'h43_5c)
            $display("Test Case Passed");
        else
            $display("Assertion Error 1: Expected %h, Received %h", 16'h43_5c, data_o);
        repeat(2)           @(posedge clk_i);
        data_i <= 64'h06_08_0f_0f_02_01_01_03; // data for test case 2
        yumi_i <= 1'b1;     @(posedge clk_i);
        yumi_i <= 1'b0;     @(posedge clk_i);
        valid_i <= 1'b1;    @(posedge clk_i);
        valid_i <= 1'b0;    @(posedge clk_i);
        start_i <= 1'b1;    @(posedge clk_i);
        start_i <= 1'b0;    @(posedge clk_i);
                            @(posedge valid_o);
                            @(posedge clk_i);
        $display("Assert Test Case 2:");
        assert(data_o == 16'h7f_6e)
            $display("Test Case Passed");
        else
            $display("Assertion Error 1: Expected %h, Received %h", 16'h7f_6e, data_o);  
                            @(posedge clk_i);               

        $stop;
    end

endmodule