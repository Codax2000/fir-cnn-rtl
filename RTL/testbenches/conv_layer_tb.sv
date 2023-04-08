`timescale 1ns / 1ps

module conv_layer_tb ();

    parameter CLOCK_PERIOD = 100;
    
    parameter INPUT_LAYER_HEIGHT=4;
    parameter KERNEL_HEIGHT=3;
    parameter KERNEL_WIDTH=2;
    parameter WORD_SIZE=8;
    parameter INT_BITS = 8;

    // control variables
    logic clk_i;
    logic reset_i;
    
    // input variables
    logic start_i;
    logic [WORD_SIZE-1:0] data_i;
    
    logic valid_o, yumi_i;
    logic [INPUT_LAYER_HEIGHT - KERNEL_HEIGHT:0][WORD_SIZE-1:0] data_o;

    assign data_i = '0; // temporary, awaiting convolutional node implementation

    conv_layer #(
        .INPUT_LAYER_HEIGHT(INPUT_LAYER_HEIGHT),
        .KERNEL_HEIGHT(KERNEL_HEIGHT),
        .KERNEL_WIDTH(KERNEL_WIDTH),
        .WORD_SIZE(WORD_SIZE),
        .INT_BITS(INT_BITS),
        .LAYER_NUMBER(1),
        .CONVOLUTION_NUMBER(0)
    ) DUT (.*);
    
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
    */
    initial begin
        reset_i <= 1'b1;    @(posedge clk_i);
        start_i <= 1'b0;
        yumi_i <= 1'b0;
        reset_i <= 1'b0;    @(posedge clk_i);
        data_i <= 8'h01;    @(posedge clk_i);
        data_i <= 8'h05;    @(posedge clk_i); 
        data_i <= 8'h03;    @(posedge clk_i);   
        data_i <= 8'h02;    @(posedge clk_i);
        data_i <= 8'h09;    @(posedge clk_i);
        start_i <= 1'b1;    
        data_i <= 8'h05;    @(posedge clk_i);
        start_i <= 1'b0;
        data_i <= 8'h00;    @(posedge clk_i);
        data_i <= 8'h01;    @(posedge clk_i);
        data_i <= '0;       @(posedge clk_i);
                            @(posedge valid_o);
        assert (data_o == 16'h43_5c)
            else $display("Assertion Error 1: Expected %h, Received %h", 16'h43_5c, data_o);
        yumi_i <= 1'b1;     @(posedge clk_i);
        yumi_i <= 1'b0;     @(posedge clk_i);

        // Test case 2
        data_i <= 8'h03;    @(posedge clk_i);
        data_i <= 8'h01;    @(posedge clk_i); 
        data_i <= 8'h01;    @(posedge clk_i);   
        data_i <= 8'h02;    @(posedge clk_i);
        data_i <= 8'h0f;    @(posedge clk_i);
        start_i <= 1'b1;    
        data_i <= 8'h0f;    @(posedge clk_i);
        start_i <= 1'b0;
        data_i <= 8'h05;    @(posedge clk_i);
        data_i <= 8'h06;    @(posedge clk_i);
        data_i <= '0;       @(posedge clk_i);
                            @(posedge valid_o);
        assert (data_o == 16'h7f_6e)
            else $display("Assertion Error 2: Expected %h, Received %h", 16'h7f_6e, data_o);
        yumi_i <= 1'b1;     @(posedge clk_i);
        $stop;
    end

endmodule