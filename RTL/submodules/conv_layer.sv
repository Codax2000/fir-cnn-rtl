`timescale 1ns / 1ps
/**
Alex Knowlton & Eugene Liu
2/28/2023

Convolutional layer module. When start is asserted, handshakes in data with ready/valid
interface and outputs data also with a ready-valid handshake. 
NOTE: Ensure that height of input data is at least 2 words greater than kernel height, or the layer
      will hang and not work properly.

parameters:
    INPUT_LAYER_HEIGHT  : height of input layer (not total number of inputs, just the height), default 64
    KERNEL_WIDTH        : width of kernel used for computation, default 2
    KERNEL_HEIGHT       : height of kernel, default 5
    WORD_SIZE           : number of bits in each piece of data, default 16
    N_SIZE              : number of fractional bits, default 12
    LAYER_NUMBER        : layer number in neural net. used for finding the correct memory file for kernel, default 1
    CONVOLUTION_NUMBER  : kernel number. also used for finding the correct memory file, default 0

control inputs:
    clk_i   : 1-bit : clock signal
    reset_i : 1-bit : reset signal
    start_i : 1-bit : signal to start computation

demanding input interface:
    valid_i : 1-bit : valid signal for input handshake
    yumi_o  : 1-bit : ready signal for input handshake
    data_i  : n-bit : incoming data. size is WORD_SIZE
    
demanding output interface
    ready_i : 1-bit : ready signal for output handshake
    valid_o : 1-bit : valid signal for output handshake
    data_o  : n-bit : outgoing data. size is WORD_SIZE

OPTIONAL INPUTS:
if VIVADO is not defined (using `define VIVADO), then add optional write port for the RAM. Add separate data_i port for RAM:
    addr_i  : n-bit : RAM address to write to. size is address width of RAM + $clog2(N_CONVOLUTIONS + 1)
    mem_data_i: n-bit: data to write to memory. size is WORD_SIZE
    wen_i   : 1-bit : write-enable bit
    
*/

module conv_layer #(

    parameter INPUT_LAYER_HEIGHT=64,
    parameter KERNEL_HEIGHT=5,
    parameter KERNEL_WIDTH=2,
    parameter WORD_SIZE=16,
    parameter N_SIZE=12,
    parameter LAYER_NUMBER=1,
    parameter N_CONVOLUTIONS=256) (
    
    // top-level signals
    input logic clk_i,
    input logic reset_i,
    input logic start_i,
    
    // uncomment for VCS or if Vivado starts working
//    `ifndef VIVADO
//    input logic [$clog2(N_CONVOLUTIONS+1)+$clog2(KERNEL_HEIGHT*KERNEL_WIDTH+1)-1:0] mem_addr_i,
//    input logic wen_i,
//    input logic [WORD_SIZE-1:0] mem_data_i,
//    `endif

    // demanding input interface
    input logic valid_i,
    output logic yumi_o,
    input logic signed [WORD_SIZE-1:0] data_i,
    
    // demanding output interface
    output logic valid_o,
    input logic ready_i,
    output logic [N_CONVOLUTIONS-1:0][WORD_SIZE-1:0] data_o
    
    );
    
    ////  START CONTROL LOGIC FSM   ////
    // counter registers for memory addresses and logic signals
    // define registers here because used in FSM, define behavior later
    localparam INPUT_SIZE = KERNEL_WIDTH * INPUT_LAYER_HEIGHT;
    localparam KERNEL_SIZE = KERNEL_HEIGHT * KERNEL_WIDTH;
    
    logic [$clog2(KERNEL_SIZE+1)-1:0] mem_count_r, mem_count_n;
    logic [$clog2(INPUT_SIZE)-1:0] consumed_count_r, consumed_count_n;

    // handshake signals
    // handshake in and out are just combination of valid and ready, shift_en is dependent on current state
    logic handshake_in, handshake_out, shift;
    assign handshake_in = valid_i && yumi_o;
    assign handshake_out = valid_o && ready_i;

    // FSM states
    enum logic [2:0] {eREADY=3'b000, eSHIFT_IN=3'b001, eFULL=3'b011, eSHIFT_OUT_1=3'b010, eSHIFT_OUT_2=3'b110} ps_e, ns_e;
    
    // next state logic
    always_comb begin
        case (ps_e)
            eREADY:
                if (start_i)
                    ns_e = eSHIFT_IN;
                else
                    ns_e = eREADY;
            eSHIFT_IN:
                if ((mem_count_n == KERNEL_WIDTH * KERNEL_HEIGHT + 1) && (mem_count_r == KERNEL_WIDTH * KERNEL_HEIGHT))
                    ns_e = eFULL;
                else
                    ns_e = eSHIFT_IN;
            eFULL:
                if (consumed_count_n == 0) // TODO: make sure that this is the correct timing
                    ns_e = eSHIFT_OUT_1;
                else    
                    ns_e = eFULL;
            eSHIFT_OUT_1:
                if (KERNEL_WIDTH != 1) // should synthesize to always true, so makes this block simpler
                    ns_e = eSHIFT_OUT_2;
                else begin
                    if (handshake_out)
                        ns_e = eSHIFT_OUT_2;
                    else
                        ns_e = eSHIFT_OUT_1;
                end
            eSHIFT_OUT_2: // always have to handshake out the last piece of data
                if (handshake_out)
                    ns_e = eREADY;
                else
                    ns_e = eSHIFT_OUT_2;
            default:
                ns_e = eREADY;
        endcase
    end

    // next state transition
    always_ff @(posedge clk_i) begin
        if (reset_i)
            ps_e <= eREADY;
        else
            ps_e <= ns_e;
    end

    ////    END CONTROL LOGIC FSM  //// 

    ////   BEGIN SUBSIDIARY CONTROL LOGIC ////
    // control memory addresses, IO logic signals, shift, consumed counter, and output handshake downsampler

    // next memory address, counter is reset if not in correct state so don't worry about that
    // counter takes 1 extra cycle to allow output handshake to happen
    always_comb begin
        if (shift) begin
            if (mem_count_n == KERNEL_SIZE + 1)
                mem_count_n = 0;
            else
                mem_count_n = mem_count_r + 1;
        end else
            mem_count_n = mem_count_r;
    end

    // consumed counter - dependent on handshake in only, for clarity
    // make sure shift, valid_o, ready_o are properly dependent on each other depending on state
    always_comb begin
        if (handshake_in) begin
            if (consumed_count_r == INPUT_SIZE - 1)
                consumed_count_n = 0;
            else
                consumed_count_n = consumed_count_r + 1;
        end else
            consumed_count_n = consumed_count_r;
    end

    // counter transition logic, reset on cycles that are non-active
    always_ff @(posedge clk_i) begin
        if (reset_i || (ps_e == eREADY)) begin
            consumed_count_r <= '0;
            mem_count_r <= '0;
        end else begin
            consumed_count_r <= consumed_count_n;
            mem_count_r <= mem_count_n;
        end
    end

    // downsampler for output handshake
    // reasoning: if we handshake in every clock cycle, we only have data to handshake out every KERNEL_WIDTH
    //            clock cycles, so we need a counter to help keep track. As simple as 1 bit with KERNEL_WIDTH=2,
    //            so not expensive, especially since it's shared across all layers. If KERNEL_WIDTH=1, this should
    //            always be true. Handled by a sub-module.
    logic handshake_out_en;

    downsampled_enable #(
        .N(KERNEL_WIDTH)
    ) handshake_out_enabler (
        .clk_i,
        .reset_i(reset_i || (ps_e != eFULL)), // reset on non-handshake-out states
        .en_i(handshake_in),
        .en_o(handshake_out_en)
    );

    // combinational block for shift, ready_o, yumi_o
    // these signals all vary from state to state, but super important to get right
    // problem 1: when handshaking input AND output data, both handshakes must happen to shift
    //            but this is not the case when only handshaking in OR out but not both
    // problem 2: handshakes out happen only every KERNEL_WIDTH clock cycles
    always_comb begin
        case (ps_e)
            default: begin // should never happen but this matches eREADY
                shift = 1'b0;
                valid_o = 1'b0;
                yumi_o = 1'b0;
            end
            eREADY: begin
                shift = 1'b0;
                valid_o = 1'b0;
                yumi_o = 1'b0;
            end
            eSHIFT_IN: begin
                yumi_o = valid_i;
                shift = handshake_in;
                valid_o = 1'b0;
            end
            eFULL: begin// this gets tricky, since it depends on handshake_out_en too
                if (handshake_out_en) begin
                    if (valid_i && ready_i) begin
                        shift = 1'b1;
                        yumi_o = 1'b1;
                        valid_o = 1'b1;
                    end else begin
                        shift = 1'b0;
                        yumi_o = 1'b0;
                        valid_o = 1'b0;
                    end
                end else begin // cannot handshake out, since no handshake out is enabled
                    valid_o = 1'b0;
                    yumi_o = valid_i;
                    shift = handshake_in;
                end
            end
            eSHIFT_OUT_1: begin
                yumi_o = 1'b0;
                if (KERNEL_WIDTH == 1) begin
                    valid_o = ready_i;
                    shift = handshake_out;
                end else begin
                    valid_o = 1'b0;
                    shift = 1'b1;
                end
            end
            eSHIFT_OUT_2: begin // always handshake out on this state
                yumi_o = 1'b0;
                valid_o = ready_i;
                shift = handshake_out; // shouldn't matter but have here to avoid inferring a latch
            end
        endcase
    end

    // combinational block for add_bias_li, sum_en_li
    // these signals fed into shift registers for layer control
    logic add_bias_li, sum_en_li;
    always_comb begin
        if (shift) begin
            add_bias_li = mem_count_r == KERNEL_SIZE;
            sum_en_li = mem_count_r != KERNEL_SIZE + 1; // TODO: Check timing and logic on this one
        end else
            {add_bias_li, sum_en_li} = 2'b00;
    end
    //// END SUBSIDIARY CONTROL LOGIC ////

    //// BEGIN DATAPATH ////
    logic [N_CONVOLUTIONS-1:0][KERNEL_HEIGHT:0][WORD_SIZE-1:0] alu_data_lo;

    // add_bias shift register
    logic [KERNEL_WIDTH*KERNEL_HEIGHT-1:0] shift_add_bias_lo;
    shift_register #(
        .WORD_SIZE(1),
        .REGISTER_LENGTH(KERNEL_HEIGHT*KERNEL_WIDTH)
    ) add_bias_shift_register (
        .data_i(add_bias_li),
        .shift_en_i(shift),
        .clk_i,
        .reset_i(reset_i || (ps_e == eREADY)),
        .data_o(shift_add_bias_lo)
    );

    // sum_en shift register
    // add_bias shift register
    logic [KERNEL_WIDTH*KERNEL_HEIGHT-1:0] shift_sum_en_lo;
    shift_register #(
        .WORD_SIZE(1),
        .REGISTER_LENGTH(KERNEL_HEIGHT*KERNEL_WIDTH)
    ) sum_en_shift_register (
        .data_i(sum_en_li),
        .shift_en_i(shift),
        .clk_i,
        .reset_i(reset_i || (ps_e == eREADY)),
        .data_o(shift_sum_en_lo)
    );

    genvar i, j;
    generate
        for (i = 0; i < N_CONVOLUTIONS; i++) begin
            // data input shift register
            logic [WORD_SIZE-1:0] mem_data_lo;
            logic [KERNEL_WIDTH*KERNEL_HEIGHT-1:0][WORD_SIZE-1:0] shift_data_lo;
            shift_register #(
                .WORD_SIZE(WORD_SIZE),
                .REGISTER_LENGTH(KERNEL_HEIGHT*KERNEL_WIDTH)
            ) data_shift_register (
                .data_i(mem_data_lo),
                .shift_en_i(shift),
                .clk_i,
                .reset_i,
                .data_o(shift_data_lo)
            );


            // kernel RAM
            logic [$clog2(KERNEL_SIZE+1)-1:0] mem_addr_li;
            
            // these lines don't compile rn because Vivado is stupid, uncomment for VCS simulation
//            `ifdef VIVADO
            assign mem_addr_li = mem_count_n;            
//            `else
//            logic wen_li;
//            localparam max_mem_index_lp = $clog2(N_CONVOLUTIONS+1)+$clog2(KERNEL_HEIGHT*KERNEL_WIDTH+1)-1;
//            assign wen_li = wen_i && (mem_addr_i[max_mem_index_lp:max_mem_index_lp-$clog2(N_CONVOLUTIONS+1)] == i + 1);
            
//            // if using synopsis, we are using a 1RW RAM, so connect addresses differently
//            assign mem_addr_li = wen_i ? mem_addr_i[$clog2(KERNEL_HEIGHT*KERNEL_WIDTH+1)-1:0] : mem_count_n;
//            `endif

            ROM_neuron #(
                .depth($clog2(KERNEL_SIZE+1)),
                .width(WORD_SIZE),
                .neuron_type(0),
                .layer_number(LAYER_NUMBER),
                .neuron_number(i)
            ) weight_mem (
                
//                // compiler-dependent connection, uncomment if using VCS or if Vivado works properly
//                `ifndef VIVADO
//                .wen_i(wen_li),
//                .data_i(mem_data_i),
//                `endif

                .addr_i(mem_addr_li),
                .data_o(mem_data_lo),
                .reset_i,
                .clk_i
            );

            // generate ALUs
            logical_unit #(
                .WORD_SIZE(WORD_SIZE),
                .INT_BITS(WORD_SIZE-N_SIZE)
            ) first_alu (
                .mem_i(mem_data_lo),
                .data_i,
    
                .add_bias(add_bias_li),
                .sum_en(sum_en_li),
    
                .clk_i,
                .reset_i(reset_i || (ps_e == eREADY) || (handshake_out && ~sum_en_li)),

                .data_o(alu_data_lo[i][0])
            );
            for (j = 0; j < KERNEL_HEIGHT; j++) begin
                localparam shift_register_index = KERNEL_HEIGHT*KERNEL_WIDTH - 1 - (j * KERNEL_WIDTH + 1);
                logical_unit #(
                    .WORD_SIZE(WORD_SIZE),
                    .INT_BITS(WORD_SIZE-N_SIZE)
                ) subsidiary_alu (
                    // indices necessary because shift register shifts in from the most significant to the least significant
                    .mem_i(shift_data_lo[shift_register_index]),
                    .data_i,
        
                    .add_bias(shift && shift_add_bias_lo[shift_register_index]),
                    .sum_en(shift && shift_sum_en_lo[shift_register_index]),
        
                    .clk_i,
                    .reset_i(reset_i || (ps_e == eREADY) || (handshake_out && !(shift && shift_sum_en_lo[shift_register_index]))),

                    .data_o(alu_data_lo[i][j+1])
            );
            end

            // assign output data
            assign data_o[i] = alu_data_lo[i][mem_count_n >> (KERNEL_WIDTH - 1)];
        end
    endgenerate

endmodule