`timescale 1ns / 1ps
/**
Alex Knowlton
4/12/2023

Single-element FIFO. Useful for interfacing between some layers.

parameters:
    WORD_SIZE:  number of bits to store

input handshake:
    wen_i:  input write enable
    data_i: input data
    full_o: signal that FIFO is full

output handshake:
    ren_i:  output read enable
    data_o: output data
    empty_o: signal that FIFO is empty

other inputs:
    reset_i: dumps current data and resets to empty
    clk_i  : input clock

*/

module single_fifo #(
    parameter WORD_SIZE=16
) (
    input logic clk_i,
    input logic reset_i,

    input logic wen_i,
    input logic [WORD_SIZE-1:0] data_i,
    output logic empty_o,

    input logic ren_i,
    output logic [WORD_SIZE-1:0] data_o,
    output logic full_o
);

    // control logic fsm
    enum logic {eEMPTY=1'b0, eFULL=1'b1} ps, ns;

    always_comb begin
        case (ps)
            eEMPTY:
                if (wen_i)
                    ns = eFULL;
                else
                    ns = eEMPTY;
            eFULL:
                if (ren_i)
                    ns = eEMPTY;
                else
                    ns = eFULL;
        endcase
    end

    always_ff @(posedge clk_i) begin
        if (reset_i)
            ps <= eEMPTY;
        else
            ps <= ns;
    end

    // output handshake signals
    assign full_o = (ps == eFULL);
    assign empty_o = ps == eEMPTY;

    // data control
    logic [WORD_SIZE-1:0] data_o_n;

    always_comb begin
        case(ps)
            eEMPTY:
                if (wen_i)
                    data_o_n = data_i;
                else
                    data_o_n = '0;
            eFULL:
                if (ren_i) begin
                    else
                        data_o_n = '0;
                end else
                    data_o_n = data_o;
        endcase
    end

    always_ff @(posedge clk_i) begin
        if (reset_i)
            data_o <= '0;
        else
            data_o <= data_o_n;
    end

endmodule