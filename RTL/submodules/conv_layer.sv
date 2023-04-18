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
    parameter KERNEL_WIDTH=2, // 2 if using i and q, 1 if using only 1 channel
    parameter WORD_SIZE=16,
    parameter INT_BITS=4, // integer bits in fixed-point arithmetic (default Q4.8)
    parameter LAYER_NUMBER=1,
    parameter CONVOLUTION_NUMBER=0) (
    
    input logic clk_i,
    input logic reset_i,
    
    // input interface
    input logic start_i,
    input logic signed [WORD_SIZE-1:0] data_i,
    
    // helpful output interface
    output logic valid_o,
    input logic yumi_i,
    output logic [INPUT_LAYER_HEIGHT - KERNEL_HEIGHT:0][WORD_SIZE-1:0] data_o);
    
    parameter NUM_ITERATIONS = KERNEL_HEIGHT * KERNEL_WIDTH;

    // control logic
    enum logic [1:0] {eREADY=2'b00, eBUSY=2'b01, eDONE=2'b10} ps, ns;

    logic [$clog2(NUM_ITERATIONS+1)-1:0] mem_addr;
    logic add_bias, sum_en;

    logic [KERNEL_HEIGHT*KERNEL_WIDTH-1:0][WORD_SIZE-1:0] data_shift_reg;
    logic signed [WORD_SIZE-1:0] mem_out;

    assign sum_en = ps == eBUSY;
    always_ff @(posedge clk_i)
        add_bias <= mem_addr == NUM_ITERATIONS;

    // next state logic
    always_comb begin
        case (ps)
            eREADY:
                if (start_i)
                    ns = eBUSY;
                else
                    ns = eREADY;
            eBUSY:
                if (add_bias)
                    ns = eDONE;
                else
                    ns = eBUSY;
            2'b11, // should never happen but good to have just in case, especially to avoid inferring a latch
            eDONE:
                if (valid_o && yumi_i) // if handshake happens, be ready to start again
                    ns = eREADY;
                else
                    ns = eDONE;
        endcase
    end

    always_ff @(posedge clk_i) begin
        if (reset_i)
            ps <= eREADY;
        else
            ps <= ns;
    end

    // counter for memory address
    up_counter #(
        .WORD_SIZE($clog2(NUM_ITERATIONS+1)),
        .INPUT_MAX(NUM_ITERATIONS)
    ) mem_address_counter (
        .start_i,
        .clk_i,
        .reset_i,

        .data_o(mem_addr)
    );

    // ROM for kernel values
    ROM_neuron #(
        .depth($clog2(NUM_ITERATIONS+1)),
        .width(WORD_SIZE),
        .neuron_type(0),
        .layer_number(LAYER_NUMBER),
        .neuron_number(CONVOLUTION_NUMBER)
    ) weight_bias_mem (
        .reset_i,
        .clk_i,
        .addr_i(mem_addr),
        .data_o(mem_out)
    );

    // shift register for holding inputs
    shift_register #(
        .WORD_SIZE(WORD_SIZE),
        .REGISTER_LENGTH(KERNEL_HEIGHT * KERNEL_WIDTH)
    ) input_shift_reg (
        .data_i,
        .shift_en_i(1'b1), // not currently used
        .clk_i,
        .reset_i,
        .data_o(data_shift_reg)
    );

    // generate 'neurons' (really just logical units from fully-connected layer)
    genvar i;
    generate
        for (i = 0; i < INPUT_LAYER_HEIGHT - KERNEL_HEIGHT + 1; i = i + 1) begin
            logical_unit #(
                .WORD_SIZE(WORD_SIZE),
                .INT_BITS(INT_BITS)
            ) LU (
                .mem_i(mem_out),
                .data_i(data_shift_reg[i*KERNEL_WIDTH]), // allow for multiple kernel widths
                .add_bias,
                .sum_en,
                .clk_i,
                .reset_i(reset_i || (valid_o && yumi_i)),
                .data_o(data_o[i])
            );
        end
    endgenerate

    assign valid_o = ps == eDONE;

endmodule