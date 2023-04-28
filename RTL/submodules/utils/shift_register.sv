`timescale 1ns / 1ps
/**
Alex Knowlton
4/8/2023

Shift register that shifts in data from the side of the most significant bit
*/
module shift_register #(
    parameter WORD_SIZE = 16,
    parameter REGISTER_LENGTH = 10
) (
    input logic [WORD_SIZE-1:0] data_i,
    input logic shift_en_i,
    
    input logic clk_i,
    input logic reset_i,

    output logic [REGISTER_LENGTH-1:0][WORD_SIZE-1:0] data_o
);

    always_ff @(posedge clk_i) begin
        if (shift_en_i) begin
            data_o[REGISTER_LENGTH-2:0] <= data_o[REGISTER_LENGTH-1:1];
            data_o[REGISTER_LENGTH-1] <= data_i;
        end else
            data_o <= data_o;
    end
endmodule