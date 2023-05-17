`timescale 1ns / 1ps
/**
if enabled, outputs TRUE every N cycles. output begins at first enable, e.g. if just reset,
the next enable signal will cause the output to be true. if INPUT_MAX = 1, will always output true.
*/

module downsampled_enable #(
    parameter N = 1
) (
    input logic clk_i,
    input logic reset_i,
    input logic en_i,
    output logic en_o
);
    logic [$clog2(N+1)-1:0] count, next_count;
            
    always_comb begin
        if (en_i) begin
            if (count == N - 1)
                next_count = '0;
            else
                next_count = count + 1;
        end else
            next_count = count;
    end
    always_ff @(posedge clk_i) begin
        if (reset_i)
            count <= '0;
        else
            count <= next_count;
    end
    assign en_o =(count == '0) && en_i && !reset_i;

endmodule