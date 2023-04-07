`timescale 1ns / 1ps
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
    parameter LAYER_NUMBER=1,
    parameter CONVOLUTION_NUMBER=0) (
    
    input logic clk_i,
    input logic reset_i,
    
    // helpful input interface
    input logic valid_i,
    output logic ready_o,
    input logic [INPUT_LAYER_HEIGHT-1:0][KERNEL_WIDTH-1:0][WORD_SIZE-1:0] data_i,
    
    // helpful output interface
    output logic valid_o,
    input logic yumi_i,
    output logic [INPUT_LAYER_HEIGHT - KERNEL_HEIGHT:0][WORD_SIZE-1:0] data_o);
    
    // control logic variables
    localparam num_iterations = KERNEL_HEIGHT * KERNEL_WIDTH;

    logic [$clog2(num_iterations)-1:0] rd_addr, rd_addr_lo; // used as memory address
    logic [WORD_SIZE-1:0] mem_lo;

    // control signal to send to neurons
    logic add_bias;
    assign add_bias = rd_addr_lo == num_iterations;

    // FSM control logic
    enum logic {eDONE=1'b0, eBUSY=1'b1} ps, ns; // present state, next state

    always_comb begin
        case (ps)
            eBUSY:
                if (add_bias)
                    ns = eDONE;
                else
                    ns = eBUSY;
            eDONE:
                if (start_i)
                    ns = eBUSY;
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
    // end FSM control logic

    up_counter #(
        .WORD_SIZE($clog2(num_iterations)),
        .INPUT_MAX(num_iterations)
    ) mem_address_counter (
        .reset_i,
        .clk_i,
        .start_i,
        .data_o(rd_addr)
    );

    always_ff @(posedge clk_i) // delay read address so that memory and address reach neurons at the same time
        rd_addr_lo <= rd_addr;

    ROM #(.depth($clog2(num_iterations)),
          .width(WORD_SIZE),
          .neuron_type(0),
          .layer_number(LAYER_NUMBER),
          .neuron_number(CONVOLUTION_NUMBER) // always 0 for convolutional
    ) conv_layer_mem (
          .clk_i,
          .addr_i(rd_addr),
          .data_o(mem_lo)
          );

    genvar i;
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
                .data_i(data_i[INPUT_LAYER_HEIGHT - KERNEL_HEIGHT + 1 + i:i]),
                .weight_i(mem_lo),
                .input_index(rd_addr_lo),
                .add_bias,
                .data_o(data_o[i])
            );
        end
    endgenerate

    // output done signal after add bias is finished
    assign done_o = ps == eDONE;
endmodule