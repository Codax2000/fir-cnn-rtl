`timescale 1ns / 1ps
`ifndef SYNOPSIS
`define VIVADO
`endif

/**
Alex Knowlton
4/3/2023

Rewritten fully-connected layer for readability and functionality, since this supports
layers of differing sizes. Assumes FIFO on both input and output.
*/


module fc_layer #(

     `ifndef VIVADO
    parameter RAM_ADDRESS_BITS = 1;
    parameter RAM_SELECT_BITS = 3;
    `endif

    parameter WORD_SIZE=16,
    parameter N_SIZE=8,
    parameter LAYER_HEIGHT=2,
    parameter PREVIOUS_LAYER_HEIGHT=4,
    parameter LAYER_NUMBER=1 ) (
    
    // demanding input interface
    input logic signed [WORD_SIZE-1:0] data_i,
    input logic valid_i,
    output logic ready_o,
    
    // helpful output interface
    output logic valid_o,
    input logic yumi_i,
    output logic [LAYER_HEIGHT-1:0][WORD_SIZE-1:0] data_o,

    input logic reset_i,
    input logic clk_i,

    `ifndef VIVADO
    input logic [RAM_ADDRESS_BITS+RAM_SELECT_BITS-1:0] mem_addr_i,
    input logic w_en_i,
    input logic [WORD_SIZE-1:0] mem_data_i,
    `endif
    );

    // manage inputs internally and pass them to neurons
    logic add_bias, add_bias_delay, sum_en; // delay add_bias to give neuron memory time to read
    logic [$clog2(PREVIOUS_LAYER_HEIGHT+1)-1:0] mem_addr;

    // FSM for control signals
    enum logic {eBUSY, eDONE} ps, ns;

    // next state logic
    always_comb begin
        case (ps)
            eBUSY:
                if (add_bias_delay) // computation is done
                    ns = eDONE;
                else
                    ns = eBUSY;
            eDONE:
                // if output handshake happens, then go back to busy
                if (valid_o && yumi_i)
                    ns = eBUSY;
                else
                    ns = eDONE;
        endcase
    end

    // transition logic
    always_ff @(posedge clk_i) begin
        if (reset_i)
            ps <= eBUSY;
        else
            ps <= ns;
    end

    // output logic
    assign ren_o = (ps == eBUSY) && !empty_i;
    assign valid_o = ps == eDONE;
    
    // up counter for memory addressing
    logic en_count;
    assign en_count = ren_o || add_bias;
    up_counter_enabled #(
        .WORD_SIZE($clog2(PREVIOUS_LAYER_HEIGHT+1)),
        .INPUT_MAX(PREVIOUS_LAYER_HEIGHT)
    ) mem_addr_counter (
        .start_i(1'b1), // tentative, but appears not to need a start signal, since it is enabled
        .clk_i,
        .reset_i,
        .en_i(en_count),
        .data_o(mem_addr)
    );

    // control signals for neurons
    logic signed [WORD_SIZE-1:0] data_to_neurons;
    assign add_bias = mem_addr == PREVIOUS_LAYER_HEIGHT;
    always_ff @(posedge clk_i) begin
        add_bias_delay <= add_bias;
        sum_en <= en_count; // strange coincidence, but it works
        data_to_neurons <= data_i;
    end

    `ifndef VIVADO
    logic [2**RAM_SELECT_BITS-1:0] mem_wen_select;
    assign mem_wen_select = w_en_i << mem_addr_i[RAM_ADDRESS_BITS+RAM_SELECT_BITS-1:RAM_SELECT_BITS];
    `endif

    // generate neurons
    genvar i;
    generate
        for (i = 0; i < LAYER_HEIGHT; i = i + 1) begin
            fc_neuron #(
                `ifndef VIVADO
                .RAM_ADDRESS_BITS(RAM_ADDRESS_BITS),
                `endif
                .WORD_SIZE(WORD_SIZE),
                .N_SIZE(N_SIZE),
                .PREVIOUS_LAYER_HEIGHT(PREVIOUS_LAYER_HEIGHT),
                .LAYER_NUMBER(LAYER_NUMBER),
                .NEURON_NUMBER(i)
            ) neuron (
                .data_i(data_to_neurons),

                // control signals
                .mem_addr_i(mem_addr),
                .sum_en,
                .add_bias(add_bias_delay),

                .reset_i(reset_i || (valid_o && yumi_i)),
                .clk_i,

                `ifndef VIVADO
                .w_en_i(mem_wen_select[i]),
                .mem_data_i,
                `endif

                .data_o(data_o[i])
            );
        end
    endgenerate
    
endmodule