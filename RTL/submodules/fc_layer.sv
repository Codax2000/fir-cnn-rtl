`timescale 1ns / 1ps
`ifndef SYNOPSIS
`define VIVADO
`endif

/**
Alex Knowlton
4/3/2023

Fully-connected neural net layer. Computes matrix multiply based on memory values stored
in internal RAMs.

Control signals:
    clk_i   : input clock
    reset_i : reset signal
    
Helpful input handshake:
    valid_i : signal that incoming data is valid
    ready_o : outgoing input acknowledge signal
    data_i  : WORD_SIZE bits. incoming data from input handshake.

Helpful output handshake:
    valid_o : signal that outgoing data is valid
    yumi_o  : signal that outgoing data has been consumed
    data_o  : outgoing data. packed array of LAYER_HEIGHT*WORD_SIZE bits.
    
Compiler-dependent write port (works if SYNOPSIS is defined, see top of file):
    w_en_i      : write enable signal
    mem_data_i  : WORD_SIZE bits. incoming data to write to RAM
    mem_addr_i  : memory address, made up of RAM select and RAM address bits, like so:
    
Memory address:
    Made up of two stages, {ram_select, ram_address}. ram_select is $clog2 of layer height, and is 1
    if only one ram in the layer. so the address mem_data_i[RAM_ADDRESS_BITS+RAM_SELECT_BITS-1:RAM_ADDRESS_BITS] gives
    the RAM selection in the layer. mem_data_i[RAM_ADDRESS_BITS-1:0] is the address within the ram, determined by the
    height of the input layer + 1 for the bias.
*/


module fc_layer #(

    parameter WORD_SIZE=16,
    parameter N_SIZE=8,
    parameter LAYER_HEIGHT=2,
    parameter PREVIOUS_LAYER_HEIGHT=4,
    parameter LAYER_NUMBER=7 ) (
        
    // demanding input interface
    input logic signed [WORD_SIZE-1:0] data_i,
    input logic valid_i,
    output logic ready_o,
    
    // helpful output interface
    output logic valid_o,
    input logic yumi_i,
    output logic [LAYER_HEIGHT*WORD_SIZE-1:0] data_o,

    `ifndef VIVADO
    input logic [RAM_ADDRESS_BITS+RAM_SELECT_BITS-1:0] mem_addr_i,
    input logic w_en_i,
    input logic [WORD_SIZE-1:0] mem_data_i,
    `endif

    input logic reset_i,
    input logic clk_i
    );

    localparam RAM_ADDRESS_BITS = (LAYER_HEIGHT == 1) ? 1 : $clog2(LAYER_HEIGHT);
    localparam RAM_SELECT_BITS = $clog2(PREVIOUS_LAYER_HEIGHT + 1);

    //// BEGIN CONTROL FSM ////
    enum logic [1:0] {eSHIFT, eBIAS, eDONE} ps_e, ns_e;

    // memory counter values
    logic [$clog2(PREVIOUS_LAYER_HEIGHT+1)-1:0] mem_count_r, mem_count_n;
    logic [$clog2(PREVIOUS_LAYER_HEIGHT+1)-1:0] mem_addr_li;
    
    // next state logic
    always_comb begin
        case (ps_e)
            eSHIFT:
                if ((mem_count_r == PREVIOUS_LAYER_HEIGHT - 1) && valid_i)
                    ns_e = eBIAS;
                else
                    ns_e = eSHIFT;
            eBIAS:
                ns_e = eDONE;
            eDONE:
                if (yumi_i)
                    ns_e = eSHIFT;
                else
                    ns_e = eDONE;
            default:
                ns_e = eSHIFT;
        endcase
    end

    // transition logic
    always_ff @(posedge clk_i) begin
        if (reset_i)
            ps_e <= eSHIFT;
        else
            ps_e <= ns_e;
    end
    
    //// END CONTROL FSM ////
    
    //// SUBSIDIARY CONTROL SIGNALS ////
    // manage inputs internally and pass them to neurons
    logic add_bias, sum_en;
    assign add_bias = ps_e == eBIAS;
    assign sum_en = (ps_e == eBIAS) || (ps_e == eSHIFT && valid_i);
    
    `ifndef VIVADO
    assign mem_addr_li = (w_en_i) ? mem_addr_i[RAM_ADDRESS_BITS-1:0] : mem_count_n;
    `else
    assign mem_addr_li = mem_count_n;
    `endif

    // next memory counter logic
    always_comb begin
        if (mem_count_r == PREVIOUS_LAYER_HEIGHT + 1)
            mem_count_n = 0;
        else if (valid_i)
            mem_count_n = mem_count_r + 1;
        else
            mem_count_n = mem_count_r;
    end
    
    always_ff @(posedge clk_i) begin
        if (reset_i || ps_e == eDONE)
            mem_count_r <= '0;
        else
            mem_count_r <= mem_count_n;
    end

    // write enable signals
    `ifndef VIVADO
    logic [2**RAM_SELECT_BITS-1:0] mem_wen_select;
    assign mem_wen_select = w_en_i << mem_addr_i[RAM_ADDRESS_BITS+RAM_SELECT_BITS-1:RAM_SELECT_BITS];
    `endif
    
    // output signals
    assign ready_o = ps_e == eSHIFT;
    assign valid_o = ps_e == eDONE;
    
    //// END SUBSIDIARY CONTROL SIGNALS ////
    
    //// BEGIN DATAPATH ////
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
                .data_i(data_i),

                // control signals
                .mem_addr_i(mem_addr_li),
                .sum_en,
                .add_bias,

                .reset_i(reset_i || (valid_o && yumi_i)),
                .clk_i,

                `ifndef VIVADO
                .w_en_i(mem_wen_select[i]),
                .mem_data_i(mem_data_i),
                `endif

                .data_o(data_o[i*WORD_SIZE+WORD_SIZE-1:i*WORD_SIZE])
            );
        end
    endgenerate
    
endmodule