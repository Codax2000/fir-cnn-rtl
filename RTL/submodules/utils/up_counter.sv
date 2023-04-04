module up_counter #(
    
    parameter WORD_SIZE = 16,
    parameter INPUT_MAX = 10) (

    input logic start_i,
    input logic clk_i,
    input logic reset_i,

    output logic [WORD_SIZE-1:0] data_o
    );

    enum {eCOUNTING=1'b0, eDONE=1'b1} ps, ns;

    // control logic
    always_comb begin
        case (ps)
            eCOUNTING:
                if (data_o == INPUT_MAX - 1)
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
        if (ps == eCOUNTING || start_i) // start counting on the next clock cycle
            data_o <= data_o + 1;
        else
            data_o <= '0;
    end

endmodule