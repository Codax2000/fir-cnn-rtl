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
    
    // still need start signal
    input logic start_i,

    // input interface
    input logic valid_i,
    output logic ready_o,
    input logic signed [WORD_SIZE-1:0] data_i,
    
    // helpful output interface
    output logic valid_o,
    input logic yumi_i,
    output logic [INPUT_LAYER_HEIGHT - KERNEL_HEIGHT:0][WORD_SIZE-1:0] data_o);
    
    localparam NUM_ITERATIONS = KERNEL_HEIGHT * KERNEL_WIDTH;

    // control logic
    enum logic [1:0] {eREADY=2'b00, eSHIFT=2'b01, eCOMPUTE=2'b10, eDONE=2'b11} ps, ns;

    // necessary control signals for internal operation, in addition to handshake signals
    logic add_bias, sum_en;

    // shift register and memory address counter
    logic [$clog2(KERNEL_HEIGHT * KERNEL_WIDTH + 1)-1:0] mem_addr;
    logic [$clog2(INPUT_LAYER_HEIGHT * KERNEL_WIDTH + 1)-1:0] shift_count;

    // memory output, sent to ALUs with data
    logic signed [WORD_SIZE - 1:0] mem_out;
    logic signed [KERNEL_WIDTH * (INPUT_LAYER_HEIGHT - KERNEL_HEIGHT + 1)-1:0][WORD_SIZE - 1:0] shift_reg_out;

    // transition signals for simplicity
    logic end_shift_stage;
    assign end_shift_stage = shift_count == KERNEL_WIDTH * (INPUT_LAYER_HEIGHT - KERNEL_HEIGHT + 1) - 1;

    assign sum_en = ps == eCOMPUTE && ((valid_i && ready_o) || shift_count == INPUT_LAYER_HEIGHT * KERNEL_WIDTH);

    // next state and transition logic
    always_comb begin
        case (ps)
            eREADY:
                if (start_i)
                    ns = eSHIFT;
                else
                    ns = eREADY;
            eSHIFT:
                if (end_shift_stage)
                    ns = eCOMPUTE;
                else
                    ns = eSHIFT;
            eCOMPUTE:
                if (add_bias)
                    ns = eDONE;
                else
                    ns = eCOMPUTE;
            eDONE:
                if (valid_o && yumi_i)
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

    // assign control logic
    always_ff @(posedge clk_i) begin
        add_bias <= mem_addr == KERNEL_HEIGHT * KERNEL_WIDTH;
    end

    up_counter_enabled #(
        .WORD_SIZE($clog2(KERNEL_HEIGHT * KERNEL_WIDTH + 1)),
        .INPUT_MAX(KERNEL_HEIGHT * KERNEL_WIDTH)
    ) mem_counter (
        .start_i(1'b1),
        .clk_i,
        .reset_i(reset_i || (valid_o && yumi_i)),      
        .en_i(((valid_i && ready_o) || sum_en) && ps == eCOMPUTE),         // enable count on input handshake

        .data_o(mem_addr)
    );

    up_counter_enabled #(
        .WORD_SIZE($clog2(INPUT_LAYER_HEIGHT * KERNEL_WIDTH + 1)),
        .INPUT_MAX(INPUT_LAYER_HEIGHT * KERNEL_WIDTH)
    ) shift_counter (
        .start_i(1'b1),
        .clk_i,
        .reset_i(reset_i || (valid_o && yumi_i)),      // reset on either transition to next state
        .en_i(valid_i && ready_o),         // enable count on input handshake

        .data_o(shift_count)
    );

    shift_register #(
        .WORD_SIZE(WORD_SIZE),
        .REGISTER_LENGTH(KERNEL_WIDTH * (INPUT_LAYER_HEIGHT - KERNEL_HEIGHT + 1))
    ) input_register (
        .data_i,
        .shift_en_i(valid_i && ready_o && (shift_count != (KERNEL_WIDTH * INPUT_LAYER_HEIGHT))),
        
        .clk_i,
        .reset_i,

        .data_o(shift_reg_out)
    );

    ROM_neuron #(
        .depth($clog2(KERNEL_HEIGHT * KERNEL_WIDTH + 1)),
        .width(WORD_SIZE),
        .neuron_type(0),
        .layer_number(LAYER_NUMBER),
        .neuron_number(CONVOLUTION_NUMBER)
    ) weight_mem (
        .reset_i,
        .clk_i,
        .addr_i(mem_addr),
        .data_o(mem_out)
    );

    genvar i;
    generate
        for (i = 0; i < INPUT_LAYER_HEIGHT - KERNEL_HEIGHT + 1; i = i + 1) begin
            logical_unit #(
                .WORD_SIZE(WORD_SIZE),
                .INT_BITS(INT_BITS)
            ) LU (
                .mem_i(mem_out),
                .data_i(shift_reg_out[i*KERNEL_WIDTH]), // allow for multiple kernel widths
                .add_bias,
                .sum_en,
                .clk_i,
                .reset_i(reset_i || (valid_o && yumi_i)),
                .data_o(data_o[i])
            );
        end
    endgenerate
    
    assign ready_o = ps == eCOMPUTE || ps == eSHIFT;
    assign valid_o = ps == eDONE;

endmodule