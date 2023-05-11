`timescale 1ns / 1ps
/**
Alex Knowlton & Eugene Liu
5/11/2023

Convolutional layer module. Outputs done when all layers finished and biased. On start,
takes data in one word at a time and outputs data in parallel via valid-ready handshakes.

parameters:
    INPUT_LAYER_HEIGHT  : height of input layer (not total number of inputs, just the height)
    KERNEL_WIDTH        : width of kernel used for computation
    KERNEL_HEIGHT       : height of kernel
    WORD_SIZE           : number of bits in each piece of data
    INT_BITS            : the 'n' of n.m fixed point notation.
    LAYER_NUMBER        : layer number in neural net. used for finding the correct memory file for kernel
    CONVOLUTION_NUMBER  : kernel number. also used for finding the correct memory file

inputs:
    clk_i   : 1-bit : clock signal
    reset_i : 1-bit : reset signal
    start_i : 1-bit : signal to start computation (to delay computation until new outputs are received)

    valid_i : 1-bit : valid signal for input handshake
    yumi_i  : 1-bit : ready signal for output handshake

    data_i  : n-bit : incoming data. size is WORD_SIZE
    

outputs:
    data_o  : n-bit : outgoing data. packed array of [INPUT_LAYER_HEIGHT - KERNEL_HEIGHT + 1][WORD_SIZE] bits,
                      where least significant word is equivalent to output[0], which should correlate to Rx[0].
    ready_o : 1-bit : ready signal for input handshake
    valid_o : 1-bit : valid signal for output handshake
*/

module convolver #(

    parameter INPUT_LAYER_HEIGHT=64,
    parameter KERNEL_HEIGHT=16,
    parameter KERNEL_WIDTH=1, // 2 if using i and q, 1 if using only 1 channel
    parameter WORD_SIZE=16,
    parameter INT_BITS=4, // integer bits in fixed-point arithmetic (default Q4.8)
    parameter LAYER_NUMBER=1,
    parameter CONVOLUTION_NUMBER=0,
    
    // derived parameters
    parameter KERNEL_SIZE = KERNEL_WIDTH*KERNEL_HEIGHT,
    parameter NUM_CHUNKS  = $rtoi($ceil($itor(INPUT_LAYER_HEIGHT*KERNEL_WIDTH)/$itor(KERNEL_SIZE)))
    
    ) (

    // top-level signals
    input logic clk_i,
    input logic reset_i,
    input logic start_i,

    // helpful interface to prev layer
    input logic valid_i,
    output logic ready_o,
    input logic signed [WORD_SIZE-1:0] data_i,
    
    // helpful interface to next layer
    output logic valid_o,
    input logic yumi_i,
    output logic [KERNEL_HEIGHT:0][WORD_SIZE-1:0] data_o);
    
    
    
    
    
// CONTROLLER 
    
    localparam NUM_ITERATIONS = KERNEL_HEIGHT * KERNEL_WIDTH;

    // controller states
    typedef enum logic [1:0] {eREADY=2'b00, eSHIFT=2'b01, eBUSY=2'b10, eDONE=2'b11} state_e;
    state_e state_n, state_r;

    // state register
    always_ff @(posedge clk_i) begin
        if (reset_i)
            state_r <= eREADY;
        else
            state_r <= state_n;
    end
    
    // next state logic
    logic is_max_kernel, is_max_chunk;
    always_comb begin
        case (state_r)
            eREADY: state_n = start_i ? eSHIFT : eREADY;
            eSHIFT: state_n = (valid_i && is_max_kernel) ? eBUSY  : eSHIFT;
            eBUSY:  state_n = (valid_i && is_max_kernel) ? eDONE  : eBUSY;
            eDONE:  state_n = (yumi_i  && is_max_chunk ) ? eSHIFT : eDONE;
            default: state_n = eREADY;
        endcase
    end
    
    // control signal logic
    logic kernel_count_en, chunk_count_en, shift_reg_en_li, sum_en_li;
    
    
    
    
    
// DATAPATH
    
    // kernel upcounter counts from 0 to KERNEL_SIZE
    logic [$clog2(KERNEL_SIZE+1)-1:0] kernel_count_r, kernel_count_n;
    always_ff @(posedge clk_i) begin
        kernel_count_r = kernel_count_n;
    end
    
    always_comb begin
        is_max_kernel = (kernel_count_r == KERNEL_SIZE+1);
    
        if (reset_i)
            kernel_count_n = '0;
        else if (kernel_count_en)
            kernel_count_n = is_max_kernel ? '0 : kernel_count_r+1;
        else
            kernel_count_n = kernel_count_r;
    end
    
    // chunk upcounter counts from 0 to NUM_CHUNKS
    logic [$clog2(NUM_CHUNKS)-1:0] chunk_count_r, chunk_count_n;
    always_ff @(posedge clk_i) begin
        chunk_count_r = chunk_count_n;
    end
    
    always_comb begin
        is_max_chunk = (chunk_count_r == NUM_CHUNKS-1);
    
        if (reset_i)
            chunk_count_n = '0;
        else if (chunk_count_en)
            chunk_count_n = is_max_chunk ? '0 : chunk_count_r+1;
        else
            chunk_count_n = chunk_count_r;
    end
    
    // shift register
    logic signed [KERNEL_SIZE:0][WORD_SIZE-1:0] shift_reg_lo;
    shift_register #(
        .WORD_SIZE(WORD_SIZE),
        .REGISTER_LENGTH(KERNEL_SIZE+1)
    ) input_register (
         .clk_i,
        .reset_i,
    
        .data_i,
        .shift_en_i(shift_reg_en_li),

        .data_o(shift_reg_lo)
    );

    // ROM with kernel weights and bias
    logic signed [WORD_SIZE-1:0] mem_lo;
    ROM_neuron #(
        .depth($clog2(KERNEL_SIZE+1)),
        .width(WORD_SIZE),
        .neuron_type(0),
        .layer_number(LAYER_NUMBER),
        .neuron_number(CONVOLUTION_NUMBER)
    ) weight_mem (
        .reset_i,
        .clk_i,
        
        .addr_i(kernel_count_r),
        .data_o(mem_lo)
    );
    
    // logical units (conv neurons)
    genvar i;
    generate
        for (i=0; i<KERNEL_HEIGHT; i=i+1) begin
            logical_unit #(
                .WORD_SIZE(WORD_SIZE),
                .INT_BITS(INT_BITS)
            ) LU (
                .reset_i(reset_i || is_max_kernel),
                .mem_i(mem_lo),
                .data_i(shift_reg_lo[i*KERNEL_WIDTH]), // allow for multiple kernel widths
                .add_bias(kernel_count_r == KERNEL_SIZE),
                .sum_en(sum_en_li),
                .clk_i,

                .data_o(data_o[i])
            );
        end
    endgenerate
    
    
    
    
    assign ready_o = (ps == eCOMPUTE && !(shift_count == INPUT_LAYER_HEIGHT * KERNEL_WIDTH)) || ps == eSHIFT;
    assign valid_o = ps == eDONE;


    // transition signals for simplicity
    logic end_shift_stage;
    assign end_shift_stage = shift_count == KERNEL_WIDTH * (INPUT_LAYER_HEIGHT - KERNEL_HEIGHT + 1) - 1;

    assign sum_en = ps == eCOMPUTE && ((valid_i && ready_o) || shift_count == INPUT_LAYER_HEIGHT * KERNEL_WIDTH);



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
        .en_i((((valid_i && ready_o) || sum_en) && ps == eCOMPUTE) || end_shift_stage),         // enable count on input handshake

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



endmodule