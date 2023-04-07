`timescale 1ns / 1ps

module up_counter_enabled_tb ();

    localparam WORD_SIZE = 16;
    localparam INPUT_MAX = 4;

    logic start_i;
    logic clk_i;
    logic reset_i;
    logic en_i;

    logic [WORD_SIZE-1:0] data_o;

    up_counter_enabled #(
        .WORD_SIZE(WORD_SIZE),
        .INPUT_MAX(INPUT_MAX)
    ) DUT (
        .*
    );

    assign start_i = 1;

    parameter CLOCK_PERIOD = 100;
    initial begin
        clk_i = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk_i = ~clk_i;
    end

    initial begin
        reset_i <= 1'b1; @(posedge clk_i);
        en_i <= 1'b1; @(posedge clk_i);
        reset_i <= 1'b0; @(posedge clk_i);

        repeat(2) @(posedge clk_i);
        en_i <= 1'b0; @(posedge clk_i);
        en_i <= 1'b1; @(posedge clk_i);
        en_i <= 1'b0; @(posedge clk_i);
        repeat(6) @(posedge clk_i);

    end

endmodule