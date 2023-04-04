/**
Alex Knowlton
4/4/2023

Output for fully-connected layer. does not implement ReLU at this time
signals ready to accept new data when writing last piece of data to output FIFO.
Serializes output of fully-connected layer
*/

module fc_output_layer #(
    parameter LAYER_HEIGHT=5,
    parameter WORD_SIZE=16 ) (
    input logic clk_i,
    input logic reset_i,
    
    input logic valid_i,
    output logic ready_o,
    input logic [LAYER_HEIGHT-1:0][WORD_SIZE-1:0] data_i,

    output logic wen_o,
    input logic full_i,
    output logic [WORD_SIZE-1:0] data_o
    );

    logic [$clog2(LAYER_HEIGHT+1)-1:0] output_addr;
    logic [LAYER_HEIGHT-1:0][WORD_SIZE-1:0] current_data;

    // control logic
    enum {eREADY=1'b1, eBUSY=1'b0} ps, ns;
    always_comb begin
        case (ps)
            eREADY:
                if (valid_i)
                    ns = eBUSY;
                else
                    ns = eREADY;
            eBUSY:
                if (output_addr == LAYER_HEIGHT && wen_o)
                    ns = eREADY;
                else
                    ns = eBUSY;
        endcase
    end

    always_ff @(posedge clk_i) begin
        if (reset_i)
            ps <= eREADY;
        else
            ps <= ns;
    end

    // output logic
    assign data_o = current_data[output_addr];
    assign ready_o = ps == eREADY;
    assign wen_o = ps == eBUSY && ~full_i;

    up_counter_enabled #(
        .WORD_SIZE($clog2(LAYER_HEIGHT+1)),
        .INPUT_MAX(LAYER_HEIGHT)
    ) counter (
        .start_i(ready_o && valid_i),
        .clk_i,
        .reset_i,
        .en_i(ps == eBUSY && ~full_i),
        .data_o(output_addr)
    );

endmodule