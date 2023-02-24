module conv_layer #(
    parameter INPUT_LAYER_HEIGHT=4,
    parameter KERNEL_HEIGHT=3,
    parameter KERNEL_WIDTH=2,
    parameter WORD_SIZE=16) (
    input logic [INPUT_LAYER_HEIGHT-1:0][KERNEL_WIDTH-1:0][WORD_SIZE-1:0] data_i,
    input logic [KERNEL_HEIGHT-1:0][KERNEL_WIDTH-1:0][WORD_SIZE-1:0] kernel_i,
    input logic [INPUT_LAYER_HEIGHT - KERNEL_HEIGHT:0][WORD_SIZE-1:0] bias_i,
    input logic clk_i,
    input logic reset_i,
    input logic start_i,
    output logic done_o,
    output logic [INPUT_LAYER_HEIGHT - KERNEL_HEIGHT:0][WORD_SIZE-1:0] data_o);
    
    logic [INPUT_LAYER_HEIGHT - KERNEL_WIDTH:0] comp_done;
    assign done_o = !(~comp_done);
    
    genvar i;
    generate
        for (i = 0; i < INPUT_LAYER_HEIGHT - KERNEL_HEIGHT + 1; i = i + 1) begin
            conv_node #(
                .KERNEL_HEIGHT(KERNEL_HEIGHT),
                .KERNEL_WIDTH(KERNEL_WIDTH),
                .WORD_SIZE(WORD_SIZE)
            ) node (
                .data_i(data_i[KERNEL_HEIGHT+i-1:i]),
                .kernel_i,
                .bias_i(bias_i[i]),
                .start_i,
                .clk_i,
                .reset_i,
                .data_o(data_o[i]),
                .done_o(comp_done[i])
            );
        end
    endgenerate
    
    
endmodule