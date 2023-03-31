/**
Alex Knowlton
2/28/2023

Convolutional layer module. Outputs done when all layers finished and biased. On start,
updates output and begins convolution again, assumed inputs are constant.

*/

module conv_layer #(

    parameter INPUT_LAYER_HEIGHT=4,
    parameter KERNEL_HEIGHT=3,
    parameter KERNEL_WIDTH=2,
    parameter WORD_SIZE=16,
    parameter MEM_INIT="conv_node_test.mif") (
    
    input logic clk_i,
    input logic reset_i,
    
    input logic start_i,
    input logic [INPUT_LAYER_HEIGHT-1:0][KERNEL_WIDTH-1:0][WORD_SIZE-1:0] data_i,
    
    output logic done_o,
    output logic [INPUT_LAYER_HEIGHT - KERNEL_HEIGHT:0][WORD_SIZE-1:0] data_o);
    
    // control logic variables
    localparam num_iterations = KERNEL_HEIGHT * KERNEL_WIDTH + 1;

    logic [$clog2(num_iterations)-1:0] rd_addr; // used as memory address, common loop
    logic [WORD_SIZE-1:0] mem_lo;
    logic add_bias;
    assign add_bias = rd_addr == num_iterations;

    enum {eDONE=1'b0, eBUSY=1'b1} ps, ns; // present state, next state

    // control logic next state
    always_comb begin
        case (ps)
            eBUSY: begin
                if (add_bias)
                    ns = eDONE;
                else
                    ns = eBUSY;
            end
            eDONE: begin
                if (start_i)
                    ns = eBUSY;
                else
                    ns = eDONE;
            end
        endcase
    end

    always_ff @(posedge clk_i) begin
        if (reset_i)
            ps <= eDONE;
        else
            ps <= ns;
    end
    // end control logic

    // counter with memory access
    always_ff @(posedge clk_i) begin
        if (add_bias || reset_i || ps == eDONE)
            rd_addr <= '0;
        else
            rd_addr <= rd_addr + 1;
    end

    ROM #(.depth($clog2(num_iterations)),
          .width(WORD_SIZE),
          .init_file(MEM_INIT)) conv_layer_mem (
          .clk_i,
          .addr_i(rd_addr),
          .data_o(mem_lo)
          );

    // TODO: generate nodes
    /**genvar i;
    generate
        for (i = 0; i < INPUT_LAYER_HEIGHT - KERNEL_HEIGHT + 1; i = i + 1) begin
            conv_node #(
                .WORD_SIZE(WORD_SIZE),
                .KERNEL_HEIGHT(KERNEL_HEIGHT),
                .KERNEL_WIDTH(KERNEL_WIDTH)
            ) node (
                .clk_i,
                .reset_i,
                .start_i,
                .ps,
                .data_i(data_i[INPUT_LAYER_HEIGHT - KERNEL_HEIGHT + i:i]),
                .weight_i(mem_lo),
                .input_index(rd_addr),
                .add_bias,
                .data_o(data_o[i])
            );
        end
    endgenerate*/

    // output done signal after add bias is finished
    assign done_o = ps == eDONE;
endmodule