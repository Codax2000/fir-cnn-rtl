`timescale 1ns / 1ps
/**
on start, counts up from 0 to INPUT_MAX, inclusive, when en_i is high. starts counting up immediately, so will
output 1 a cycle after start_i is asserted, and so on.
*/

module up_counter_enabled #(
    
    parameter WORD_SIZE = 16,
    parameter INPUT_MAX = 10) (

    input logic start_i,
    input logic clk_i,
    input logic reset_i,
    input logic en_i,

    output logic [WORD_SIZE-1:0] data_o
    );

    enum logic {eCOUNTING=1'b0, eDONE=1'b1} ps, ns;

    // control logic
    always_comb begin
        case (ps)
            eCOUNTING:
                // note: true here only because we use the last index as the bias, otherwise would be (data_o == INPUT_MAX && en_i)
                if (data_o == INPUT_MAX)
                    ns = eDONE;
                else
                    ns = eCOUNTING;
            eDONE:
                if (start_i)
                    ns = eCOUNTING;
                else
                    ns = eDONE;
        endcase
    end

    always_ff @(posedge clk_i) begin
        if (reset_i)
            ps <= eDONE;
        else
            ps <= ns;
    end

    // counting logic
    always_ff @(posedge clk_i) begin
        if (ns == eDONE)
            data_o <= '0;
        else if ((ps == eCOUNTING || start_i) && en_i) // start counting on the next clock cycle
            data_o <= data_o + 1;
        else if ((ps == eCOUNTING || start_i) && ~en_i)
            data_o <= data_o;
        else
            data_o <= '0;
    end

endmodule