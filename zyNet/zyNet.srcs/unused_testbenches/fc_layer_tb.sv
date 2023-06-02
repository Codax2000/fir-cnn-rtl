`timescale 1ns / 1ps

module fc_layer_tb ();

    localparam WORD_SIZE = 8;
    localparam INPUT_LAYER_HEIGHT = 4;
    localparam TEST_LAYER_HEIGHT = 2;

    logic [INPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] val_in;
    logic [TEST_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] val_out;
    logic [WORD_SIZE-1:0] input_fifo_in, input_fifo_out, output_layer_out, output_fifo_out;

    // global clock and reset signals
    logic clk, reset;

    // input serializer handshake
    logic valid_input, ready_input;

    // input fifo handshake
    logic wen_input_fifo, full_input_fifo;

    // DUT handshake
    logic empty_dut, ren_dut;

    // output layer handshake
    logic valid_output_layer, ready_output_layer;

    // output fifo handshake
    logic full_output_fifo, wen_output_fifo;

    // output value handshake
    logic empty_out, ren_out;

    fc_output_layer #(
        .WORD_SIZE(WORD_SIZE),
        .LAYER_HEIGHT(INPUT_LAYER_HEIGHT)
    ) input_layer (
        .clk_i(clk),
        .reset_i(reset),

        .valid_i(valid_input),
        .ready_o(ready_input),
        .data_i(val_in),

        .wen_o(wen_input_fifo),
        .full_i(full_input_fifo),
        .data_o(input_fifo_in)
    );

    double_fifo #(
        .WORD_SIZE(WORD_SIZE)
    ) input_fifo (
        .clk_i(clk),
        .reset_i(reset),

        .wen_i(wen_input_fifo),
        .ren_i(ren_dut),
        .data_i(input_fifo_in),

        .full_o(full_input_fifo),
        .empty_o(empty_dut),
        .data_o(input_fifo_out)
    );

    fc_layer #(
        .WORD_SIZE(WORD_SIZE),
        .INT_BITS(WORD_SIZE),
        .LAYER_HEIGHT(TEST_LAYER_HEIGHT),
        .PREVIOUS_LAYER_HEIGHT(INPUT_LAYER_HEIGHT),
        .LAYER_NUMBER(1)
    ) DUT (
        // demanding interface
        .data_i(input_fifo_out),
        .empty_i(empty_dut),
        .ren_o(ren_dut),

        // demanding interface
        .valid_o(valid_output_layer),
        .ready_i(ready_output_layer),
        .data_o(val_out),

        .reset_i(reset),
        .clk_i(clk),

        // input for back-propagation, not currently used
        .weight_i('0),
        .mem_wen_i(1'b0)
    );

    fc_output_layer #(
        .WORD_SIZE(WORD_SIZE),
        .LAYER_HEIGHT(TEST_LAYER_HEIGHT)
    ) output_layer (
        .clk_i(clk),
        .reset_i(reset),

        .valid_i(valid_output_layer),
        .ready_o(ready_output_layer),
        .data_i(val_out),

        .wen_o(wen_output_fifo),
        .full_i(full_output_fifo),
        .data_o(output_layer_out)
    );

    double_fifo #(
        .WORD_SIZE(WORD_SIZE)
    ) output_fifo (
        .clk_i(clk),
        .reset_i(reset),

        .wen_i(wen_output_fifo),
        .ren_i(ren_out),
        .data_i(output_layer_out),

        .full_o(full_output_fifo),
        .empty_o(empty_out),
        .data_o(output_fifo_out)
    );

    parameter CLOCK_PERIOD = 100;
    initial begin
        clk = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk = ~clk;
    end

    // manipulate ren_i, data_i, valid_i,
    initial begin
        val_in <= 32'h04_01_03_02; // test case 1
        ren_out <= 1'b0; // just leave off for now
        reset <= 1'b1;          @(posedge clk);
        reset <= 1'b0;
        valid_input <= 1'b1;    @(posedge clk);
        valid_input <= 1'b0;    @(negedge empty_out);
        ren_out <= 1'b1;        @(posedge clk);
        val_in <= 32'h18_21_15_11; // test case 2, something that will definitely cause overflow on at least one input
        assert(8'h53 == output_fifo_out)
            else $display("Assertion Error 1: Expected %h, Received %h", 8'h53, output_fifo_out);
        ren_out <= 1'b0;        @(posedge clk);
        valid_input <= 1'b1;
        ren_out <= 1'b1;        @(posedge clk);
        assert(8'hd9 == output_fifo_out)
            else $display("Assertion Error 2: Expected %h, Received %h", 8'hd9, output_fifo_out);
        valid_input <= 1'b0;
        ren_out <= 1'b0;        @(negedge empty_out);
        ren_out <= 1'b1;        @(posedge clk);
        assert(8'h7f == output_fifo_out)
            else $display("Assertion Error 3: Expected %h, Received %h", 8'h7f, output_fifo_out);
        ren_out <= 1'b0;        @(posedge clk);
        ren_out <= 1'b1;        @(posedge clk);
        assert(8'h7f == output_fifo_out)
            else $display("Assertion Error 4: Expected %h, Received %h", 8'h7f, output_fifo_out);
                                @(posedge clk);
        $stop;
    end

endmodule