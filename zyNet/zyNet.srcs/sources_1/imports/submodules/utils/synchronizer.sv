`timescale 1ns / 1ps
/**
Alex Knowlton
5/27/2023

1-input synchronizer. Takes an input, passes it through 2 flip flops and debounces
it such that a noisy input will become a 1-input high signal. Requires the input to
be true for 16 cycles before asserting the output true signal for 1 cycle, then
requires the input to be false for 10 cycles before being able to assert again. The
idea is to prevent glitches in inputs for cleaner testing on the FPGA.

Inputs:
    data_i : 1-bit input signal to synchronize.
    clk_i  : input clock
    reset_i: reset signal

Outputs:
    data_o : 1-bit output signal, true for 1 clock cycle.

Example operation (Each character: 1 clock cycle). Run synchronizer_tb.sv for close simulation
             __    __    ______     __________________
data_i : ___/  \__/  \__/      \___/                  \_____________
                                              __
data_o : ____________________________________/  \___________________
*/

module synchronizer (
    input  logic clk_i,
    input  logic data_i,
    input  logic reset_i,
    output logic data_o
);

localparam CLOCKS_BEFORE_ASSERT = 16;

//// SYNCHRONIZER
logic data_i_r, data_i_r_r;
always_ff @(posedge clk_i) begin
    data_i_r <= data_i;
    data_i_r_r <= data_i_r;
end

//// OUTPUT ASSERTION
enum logic {eASSERT, eDEASSERT} ps_e, ns_e;
logic [$clog2(CLOCKS_BEFORE_ASSERT)-1:0] count_n, count_r;

// Control Logic
always_comb begin
    case (ps_e)
        eASSERT:
            ns_e = (count_n == CLOCKS_BEFORE_ASSERT - 1) ? eDEASSERT : eASSERT;
        eDEASSERT:
            ns_e = (count_n == CLOCKS_BEFORE_ASSERT - 1) ? eASSERT : eDEASSERT;
    endcase
end

always_ff @(posedge clk_i) begin
    if (reset_i)
        ps_e <= eASSERT;
    else
        ps_e <= ns_e;
end

// output control
always_comb begin
    case (ps_e)
        eASSERT:
            count_n = data_i_r_r ? (count_r + 1) : '0;
        eDEASSERT:
            count_n = !data_i_r_r ? (count_r + 1) : '0;
    endcase
end

always_ff @(posedge clk_i) begin
    if (reset_i)
        count_r <= '0;
    else
        count_r <= count_n;
end

assign data_o = (ps_e == eASSERT) && (ns_e == eDEASSERT);

endmodule