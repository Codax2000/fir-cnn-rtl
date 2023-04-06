module fc_layer_tb ();

    localparam WORD_SIZE = 8;
    localparam INPUT_LAYER_HEIGHT = 4;
    localparam TEST_LAYER_HEIGHT = 2;

    fc_output_layer #(
        .WORD_SIZE(WORD_SIZE),
        .LAYER_HEIGHT(INPUT_LAYER_HEIGHT)
    ) input_layer (
        .clk_i,
        .reset_i,

        .valid_i,
        .ready_o,
        .data_i,

        .wen_o,
        .full_i,
        .data_o
    );

    double_fifo #(
        .WORD_SIZE(WORD_SIZE)
    ) input_fifo (
        .clk_i,
        .reset_i,
        .wen_i,
        .ren_i,
        .data_i,

        .full_o,
        .empty_o,
        .data_o
    );

    fc_layer #(
        .WORD_SIZE(WORD_SIZE),
        .LAYER_HEIGHT(TEST_LAYER_HEIGHT),
        .PREVIOUS_LAYER_HEIGHT(PREVIOUS_LAYER_HEIGHT),
        .LAYER_NUMBER(1)
    ) DUT (
        // demanding interface
        .data_i,
        .empty_i,
        .wen_o,

        // demanding interface
        .valid_i,
        .ready_o,
        .data_o,

        .reset_i,
        .clk_i,

        // input for back-propagation, not currently used
        .weight_i('0),
        .mem_wen_i(1'b0)
    );

    fc_output_layer #(
        .WORD_SIZE(WORD_SIZE),
        .LAYER_HEIGHT(TEST_LAYER_HEIGHT)
    ) output_layer (
        .clk_i,
        .reset_i,

        .valid_i,
        .ready_o,
        .data_i,

        .wen_o,
        .full_i,
        .data_o
    );

    double_fifo #(
        .WORD_SIZE(WORD_SIZE)
    ) output_fifo (
        .clk_i,
        .reset_i,
        .wen_i,
        .ren_i,
        .data_i,

        .full_o,
        .empty_o,
        .data_o
    );

    parameter CLOCK_PERIOD = 100;
    initial begin
        clk_i = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk_i = ~clk_i;
    end

    // manipulate ren_i, data_i, valid_i,
    initial begin
        data_i <= 32'haf_10_14_36; // test case 1
        reset_i <= 1'b1; @(posedge clk_i);

        data_i <= 32'h11_01_a1_11; // test case 2
        $stop;
    end

endmodule