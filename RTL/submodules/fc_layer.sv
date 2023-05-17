`timescale 1ns / 1ps
/**
Alex Knowlton
4/3/2023

Rewritten fully-connected layer for readability and functionality, since this supports
layers of differing sizes. Assumes FIFO on both input and output.
*/


module fc_layer #(
    parameter WORD_SIZE=16,
    parameter N_SIZE=8,
    parameter LAYER_HEIGHT=2,
    parameter PREVIOUS_LAYER_HEIGHT=4,
    parameter LAYER_NUMBER=1 ) (
    
    // demanding input interface
    input logic signed [WORD_SIZE-1:0] data_i,
    input logic empty_i,
    output logic ren_o, // also yumi_o, but not using that convention here
    
    // helpful output interface
    output logic valid_o,
    input logic yumi_i,
    output logic [LAYER_HEIGHT-1:0][WORD_SIZE-1:0] data_o,

    input logic reset_i,
    input logic clk_i,

    // input for back-propagation, not currently used
    input logic [LAYER_HEIGHT-1:0][WORD_SIZE-1:0] weight_i,
    input logic mem_wen_i
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

    // generate neurons
    genvar i;
    generate
        for (i = 0; i < LAYER_HEIGHT; i = i + 1) begin
            fc_neuron #(
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

                .data_o(data_o[i])
            );
        end
    endgenerate
    
endmodule