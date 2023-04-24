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
    
    parameter NUM_ITERATIONS = KERNEL_HEIGHT * KERNEL_WIDTH;

    // control logic
    enum logic [1:0] {eREADY=2'b00, eSHIFT=2'b01, eCOMPUTE=2'b10, eDONE=2'b11} ps, ns;

    // necessary control signals for internal operation, in addition to handshake signals
    logic add_bias, sum_en, shift_en;

    // shift register and memory address counter
        // In SHIFT stage, tracks how many values in shift register.
        // In COMPUTE stage, tracks current memory address
    logic [$clog2(KERNEL_HEIGHT * KERNEL_WIDTH + 1)-1:0] shift_and_mem_addr_count;

    // memory output, sent to ALUs with data
    logic signed [WORD_SIZE - 1:0] mem_out;

    // next state and transition logic
    always_comb begin
        case (ps)
            eREADY:
                if (start_i)
                    ns = eSHIFT;
                else
                    ns = eREADY;
            eSHIFT:
                if (shift_and_mem_addr_count == ((INPUT_LAYER_HEIGHT - KERNEL_HEIGHT + 1) * KERNEL_WIDTH)):
                    ns = eCOMPUTE;
                else
                    ns = eSHIFT;
            eCOMPUTE:
                if (add_bias):
                    ns = eDONE;
                else
                    ns = eCOMPUTE;
            eDONE:
                if (valid_o && yumi_i):
                    ns = eREADY;
                else
                    ns = eDONE;
        endcase
    end

    // assign control logic
    always_ff @(posedge clk_i) begin
        add_bias <= ps == eCOMPUTE && (shift_and_mem_addr_count == KERNEL_HEIGHT * KERNEL_WIDTH);
    end

    up_counter_enabled #(
        .WORD_SIZE($clog2(KERNEL_HEIGHT * KERNEL_WIDTH + 1)),
        .INPUT_MAX(KERNEL_HEIGHT*KERNEL_WIDTH)
    ) shift_and_mem_counter (
        .start_i(1'b1),
        .clk_i,
        .reset_i,
        .en_i(ready_o && valid_i),

        .data_o(shift_and_mem_addr_count)
    );


endmodule