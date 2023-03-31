/**
Alex Knowlton
2/28/2023

fully-connected layer
asserts done when first node is done (since all of them work at the same time this is fine)
*/

module fc_layer #(
    parameter INPUT_HEIGHT=4,
    parameter OUTPUT_HEIGHT=3,
    parameter WORD_SIZE=16,
    parameter LAYER_NUM=1) (
    input logic [INPUT_HEIGHT-1:0][WORD_SIZE-1:0] data_i,
    input logic clk_i,
    input logic reset_i,
    input logic start_i,
    output logic [OUTPUT_HEIGHT-1:0][WORD_SIZE-1:0] data_o,
    output logic done_o
);

    logic [OUTPUT_HEIGHT-1:0] done_outputs;

    genvar i;
    generate
        for (i = 0; i < OUTPUT_HEIGHT; i++) begin
            fc_node #(
                .INPUT_HEIGHT(INPUT_HEIGHT),
                .WORD_SIZE(WORD_SIZE),
                .LAYER_NUM(LAYER_NUM), // number parameters used for memory initialization
                .NODE_NUM(i)
            ) node (
                .data_i,
                .clk_i,
                .reset_i,
                .start_i,
                .data_o(data_o[i]),
                .done_o(done_outputs[i])
            );
        end
    endgenerate

    assign done_o = ~done_outputs == '0;

endmodule