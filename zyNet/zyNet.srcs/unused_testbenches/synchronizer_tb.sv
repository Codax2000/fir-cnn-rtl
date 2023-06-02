`timescale 1ns / 1ps

module synchronizer_tb ();

    logic clk_i, data_i, data_o, reset_i;

    synchronizer DUT (.*);

    // clock
    parameter CLOCK_PERIOD = 40;

    initial begin
        clk_i = 1'b1;
        forever #(CLOCK_PERIOD/2) clk_i <= !clk_i;
    end

    // testbench
    initial begin
        reset_i <= 1'b1;
        data_i <= 1'b0; @(posedge clk_i);
        reset_i <= 1'b0;
        data_i <= 1'b1; @(posedge clk_i);
        data_i <= 1'b0; @(posedge clk_i);
        data_i <= 1'b1; repeat(4) @(posedge clk_i);
        data_i <= 1'b0; repeat(2) @(posedge clk_i);
        data_i <= 1'b1; @(posedge clk_i);
        data_i <= 1'b0; @(posedge clk_i);
        data_i <= 1'b1; repeat(18) @(posedge clk_i);
        data_i <= 1'b0; @(posedge clk_i);
        data_i <= 1'b1; @(posedge clk_i);
        data_i <= 1'b0; repeat(5) @(posedge clk_i);
        data_i <= 1'b1; @(posedge clk_i);
        data_i <= 1'b0; repeat(20) @(posedge clk_i);
        data_i <= 1'b1; repeat(19) @(posedge clk_i);
        data_i <= 1'b0;
    end
endmodule