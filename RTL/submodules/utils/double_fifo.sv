/**
Alex Knowlton
4/3/2023

Two-element, first-word fall-through FIFO, used for storing items between layers of the CNN.

parameters:
    WORD_SIZE: number of bits in the data values

inputs:
    clk_i   : input clock
    reset_i : input reset
    wen_i   : write enable
    ren_i   : read enable
    data_i  : input data value

outputs:
    full_o  : true if fifo is full
    empty_o : true if fifo is empty
    data_o  : current output data (first-word fall through)
*/

module double_fifo #(
    WORD_SIZE = 16 ) (
    input logic clk_i,
    input logic reset_i,
    input logic wen_i,
    input logic ren_i,
    input logic [WORD_SIZE-1:0] data_i,

    output logic full_o,
    output logic empty_o,
    output logic [WORD_SIZE-1:0] data_o
    );

    logic [1:0] data_contained, next_data_contained; // true if data is contained in respective registers
    logic [WORD_SIZE-1:0] mid_data, next_mid_data, next_data_out;
    logic shift;

    // control logic
    always_ff @(posedge clk_i) begin
        if (reset_i)
            data_contained <= 2'b00;
        else
            data_contained <= next_data_contained;
    end

    always_comb begin
        case (data_contained)
            2'b00:
                if (wen_i)
                    next_data_contained = 2'b01;
                else
                    next_data_contained = 2'b00;
            2'b10, // should never occur but add to avoid inferring a latch
            2'b01:
                if (wen_i && ~ren_i)
                    next_data_contained = 2'b11;
                else if (~wen_i && ren_i)
                    next_data_contained = 2'b00;
                else
                    next_data_contained = 2'b01;
            2'b11:
                if (ren_i && ~wen_i)
                    next_data_contained = 2'b01;
                else
                    next_data_contained = 2'b11;
        endcase
    end

    // data logic
    always_comb begin
        case (data_contained)
            2'b00:
                if (wen_i) begin
                    next_data_out = data_i;
                    next_mid_data = '0;
                end else begin
                    next_data_out = '0; // should not matter, since FIFO is empty, but safe to have nevertheless
                    next_mid_data = '0;
                end
            2'b10, // should never occur but add to avoid inferring a latch
            2'b01:
                if (wen_i && ~ren_i) begin
                    next_data_out = data_o;
                    next_mid_data = data_i;
                end else if (~wen_i && ren_i) begin
                    next_data_out = '0;
                    next_mid_data = '0;
                end else if (wen_i && ren_i) begin
                    next_data_out = data_i;
                    next_mid_data = '0;
                end else begin
                    next_data_out = data_o;
                    next_mid_data = '0;
                end
            2'b11:
                if (ren_i && ~wen_i) begin
                    next_data_out = mid_data;
                    next_mid_data = '0;
                end else if (ren_i && wen_i) begin
                    next_data_out = mid_data;
                    next_mid_data = data_i;
                end else begin
                    next_data_out = data_o;
                    next_mid_data = mid_data;
                end
        endcase
    end

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            data_o <= '0;
            mid_data <= '0;
        end else begin
            data_o <= next_data_out;
            mid_data <= next_mid_data;
        end
    end

    // output logic
    assign full_o = (data_contained == 2'b11) && ~ren_i; // only full if we have two values and not reading
    assign empty_o = data_contained == 2'b00;

endmodule