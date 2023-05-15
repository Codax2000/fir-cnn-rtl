`timescale 1ns / 1ps
/**
Alex Knowlton & Eugene Liu
5/11/2023

Convolutional layer helper module. Consumes inputs serially and produces outputs in parallel.

Interface: Is a helpful consumer and producer, using valid-ready handshakes.

Parameters:
    INPUT_LAYER_HEIGHT  : height of input layer (not total number of inputs, just the height)
    KERNEL_WIDTH        : width of kernel used for computation
    KERNEL_HEIGHT       : height of kernel
    WORD_SIZE           : number of bits in each piece of data
    INT_BITS            : the 'n' of n.m fixed point notation.
    LAYER_NUMBER        : layer number in neural net. used for finding the correct memory file for kernel
    CONVOLUTION_NUMBER  : kernel number. also used for finding the correct memory file
    
Derived Parameters
    KERNEL_SIZE : the number of weight learnables in a kernel
    NUM_SETS    : the number of whole KERNEL_SIZE+1 word chunks (sets) that the input tensor can be divided into
    REM_WORDS   : the number of remaining words after dividing the input tensor into sets
    REM_OUTPUTS : the number of valid outputs that can be generated from REM_WORDS

Inputs-Outputs
    clk_i       : clock signal
    reset_i     : reset signal
    start_i     : signal to start computation (to delay computation until new outputs are received)

    ready_o     : handshake to prev layer. Indicates this layer is ready to recieve
    valid_i     : handshake to prev layer. Indicates prev layer has valid data
    data_i      : handshake to prev layer. The parallel data from the prev layer to this layer
    
    valid_o     : handshake to next layer. Indicates this layer has valid data
    ready_i     : handshake to next layer. Indicates next layer is ready to receive
    data_o      : handshake to next layer. The data from this layer to the next layer
    data_size_o : handshake to next layer. The number of valid words
*/

module convolve #(

    parameter INPUT_LAYER_HEIGHT=64,
    parameter KERNEL_HEIGHT=16,
    parameter KERNEL_WIDTH=1,
    parameter WORD_SIZE=16,
    parameter INT_BITS=4,
    parameter LAYER_NUMBER=1,
    parameter CONVOLUTION_NUMBER=0,
    
    // derived parameters. Don't need to touch!
    parameter KERNEL_SIZE = KERNEL_WIDTH*KERNEL_HEIGHT,
    parameter SET_SIZE    = KERNEL_SIZE+KERNEL_WIDTH,
    parameter NUM_SETS    = $rtoi($floor($itor(INPUT_LAYER_HEIGHT*KERNEL_WIDTH)/$itor(SET_SIZE))),
    parameter REM_WORDS   = (INPUT_LAYER_HEIGHT*KERNEL_WIDTH)%(SET_SIZE),
    parameter REM_OUTPUTS = REM_WORDS/KERNEL_WIDTH+2) (

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
    input logic ready_i,
    output logic signed [KERNEL_HEIGHT:0][WORD_SIZE-1:0] data_o,
    output logic [$clog2(KERNEL_HEIGHT+1)-1:0] data_size_o);
    
    
    
    
    
// CONTROLLER 
    
    // controller states
    typedef enum logic [1:0] {eREADY=2'b00, eBUSY=2'b01, eDONE=2'b10} state_e;
    state_e state_n, state_r;

    // state register
    always_ff @(posedge clk_i) begin
        if (reset_i)
            state_r <= eREADY;
        else
            state_r <= state_n;
    end
    
    // control signals
    logic [$clog2(SET_SIZE)-1:0] mem_count_r;
    logic [$clog2(NUM_SETS)-1:0] set_count_r;
    logic is_last_mem, is_last_bias, is_last_set;
    
    
    // next state logic
    always_comb begin
        case (state_r)
            eREADY: state_n = start_i ? eBUSY : eREADY;
            eBUSY: begin
                case (set_count_r)
                    0:        state_n = eBUSY;
                    NUM_SETS: state_n = is_last_mem ? eDONE : eBUSY;
                    default:  state_n = (is_last_mem && valid_i) ? eDONE : eBUSY;
                endcase
            end
            eDONE: begin
                if (ready_i)
                    state_n = is_last_set ? eREADY : eBUSY;
                else
                    state_n = eDONE;
            end
            default: state_n = eREADY;
        endcase
    end
    
    
    // output signal logic
    assign ready_o = (state_r == eBUSY) && ((mem_count_r < REM_WORDS) || (set_count_r < NUM_SETS));
    assign valid_o = (state_r == eDONE);
    
    // control signal logic
    logic consume_en, produce_en, mem_count_en, set_count_en, reg_en_li, sum_en_li, add_bias_li;
    assign consume_en = ready_o && valid_i;
    assign produce_en = valid_o && ready_i;
    
    assign mem_count_en = (state_r == eBUSY && is_last_set && mem_count_r >= REM_WORDS) || consume_en;
    assign set_count_en = (state_r == eBUSY && set_count_r == 0 && is_last_mem) || produce_en;
    assign reg_en_li    = mem_count_en;
    assign sum_en_li    = set_count_r > 0 && mem_count_r <= KERNEL_SIZE && (is_last_set && mem_count_r >= REM_WORDS || consume_en);
    assign add_bias_li  = is_last_bias;
    
    
    
    
    
// DATAPATH
    
    // kernel upcounter counts from 0 to SET_SIZE
    logic [$clog2(SET_SIZE)-1:0] mem_count_n;
    always_ff @(posedge clk_i) begin
        mem_count_r = mem_count_n;
    end
    
    always_comb begin
        is_last_bias = (mem_count_r == KERNEL_SIZE);
        is_last_mem  = (mem_count_r == SET_SIZE-1);
    
        if (reset_i)
            mem_count_n = '0;
        else if (mem_count_en)
            mem_count_n = is_last_mem ? '0 : mem_count_r+1;
        else
            mem_count_n = mem_count_r;
    end
    
    // set upcounter counts from 0 to NUM_SETS
    logic [$clog2(NUM_SETS)-1:0] set_count_n;
    always_ff @(posedge clk_i) begin
        set_count_r = set_count_n;
    end
    
    always_comb begin
        is_last_set = (set_count_r == NUM_SETS);
    
        if (reset_i)
            set_count_n = '0;
        else if (set_count_en)
            set_count_n = is_last_set ? '0 : set_count_r+1;
        else
            set_count_n = set_count_r;
    end
    
    // shift register
    logic signed [SET_SIZE-1:0][WORD_SIZE-1:0] shift_reg_lo;
    shift_register #(
        .WORD_SIZE(WORD_SIZE),
        .REGISTER_LENGTH(SET_SIZE)
    ) input_register (
        .clk_i,
        .reset_i,
    
        .data_i,
        .shift_en_i(reg_en_li),

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
        
        .addr_i(mem_count_n),
        .data_o(mem_lo)
    );
    
    // logical units (conv neurons)
    genvar i;
    generate
        for (i=0; i<KERNEL_HEIGHT+1; i=i+1) begin
            logical_unit #(
                .WORD_SIZE(WORD_SIZE),
                .INT_BITS(INT_BITS)
            ) LU (
                .clk_i,
                .reset_i(reset_i || produce_en),
                
                .mem_i(mem_lo),
                .data_i(shift_reg_lo[i*KERNEL_WIDTH]), // allow for multiple kernel widths
                .add_bias(add_bias_li),
                .sum_en(sum_en_li),

                .data_o(data_o[i])
            );
        end
    endgenerate
    
    // output logic
    assign data_size_o = is_last_set ? REM_OUTPUTS : KERNEL_HEIGHT+1;

endmodule