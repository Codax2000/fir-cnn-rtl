`timescale 1ns / 1ps
`ifndef SYNOPSIS
`define VIVADO
`endif

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
    RAM_SELECT_BITS     : number of bits in ram select
    RAM_ADDRESS_BITS    : number of bits in ram address

control signals:
    clk_i   : 1-bit : clock signal
    reset_i : 1-bit : reset signal
    start_i : 1-bit : signal to start computation
    conv_ready_o: 1-bit: signal that convolution is ready to begin computation on a new string of input data

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
    addr_i  : n-bit : RAM address to write to. size is address width of RAM_SELECT_BITS + RAM_ADDRESS_BITS
    w_data_i: n-bit: data to write to memory. size is WORD_SIZE
    w_en_i  : 1-bit : write-enable bit
    
*/

module conv_layer #(
    parameter INPUT_LAYER_HEIGHT=5,
    parameter KERNEL_HEIGHT=3,
    parameter KERNEL_WIDTH=2,
    parameter WORD_SIZE=16,
    parameter N_SIZE=0,
    parameter LAYER_NUMBER=1,
    parameter N_CONVOLUTIONS=1,
    parameter RAM_SELECT_BITS = (N_CONVOLUTIONS) == 1 ? 1 : $clog2(N_CONVOLUTIONS),
    parameter RAM_ADDRESS_BITS = $clog2(KERNEL_HEIGHT*KERNEL_WIDTH+1)
    ) (
    
    // top-level signals
    input logic clk_i,
    input logic reset_i,
    
    input logic start_i,
    output logic conv_ready_o,
    
   `ifndef VIVADO
   input logic [RAM_ADDRESS_BITS+RAM_SELECT_BITS-1:0] w_addr_i,
   input logic w_en_i,
   input logic [WORD_SIZE-1:0] w_data_i,
   `endif

    // demanding input interface
    input logic valid_i,
    output logic yumi_o,
    input logic signed [WORD_SIZE-1:0] data_i,
    
    // demanding output interface
    output logic valid_o,
    input logic ready_i,
    // no packed arrays as IO, or they will get screwed up in synthesis
    output logic [(N_CONVOLUTIONS*WORD_SIZE)-1:0] data_o
    
    );
    
    
    
    ////  START CONTROL LOGIC FSM   ////
    // counter registers for memory addresses and logic signals
    // define registers here because used in FSM, define behavior later
    localparam INPUT_SIZE = KERNEL_WIDTH * INPUT_LAYER_HEIGHT;
    localparam KERNEL_SIZE = KERNEL_HEIGHT * KERNEL_WIDTH;
    
    logic [$clog2(KERNEL_SIZE+1)-1:0] mem_count_r, mem_count_n;
    logic [$clog2(INPUT_SIZE)-1:0] consumed_count_r, consumed_count_n;

    // handshake signals
    // shift_en is dependent on current state
    logic shift;

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
                if ((mem_count_r == KERNEL_SIZE) && (mem_count_n == KERNEL_SIZE + 1))
                    ns_e = eFULL;
                else
                    ns_e = eSHIFT_IN;
            eFULL:
                if (consumed_count_n == 0)
                    ns_e = eSHIFT_OUT_1;
                else    
                    ns_e = eFULL;
            eSHIFT_OUT_1:
                if (KERNEL_WIDTH != 1) // should synthesize to always true, so makes this block simpler
                    ns_e = eSHIFT_OUT_2;
                else begin
                    if (ready_i)
                        ns_e = eSHIFT_OUT_2;
                    else
                        ns_e = eSHIFT_OUT_1;
                end
            eSHIFT_OUT_2: // always have to handshake out the last piece of data
                if (ready_i)
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

    // conv_ready signal: more of a convenience for a user
    assign conv_ready_o = ps_e == eREADY;
    
    // next memory address, counter is reset if not in correct state so don't worry about that
    // counter takes 1 extra cycle to allow output handshake to happen
    always_comb begin
        if (shift) begin
            if (mem_count_r == KERNEL_SIZE + 1)
                mem_count_n = 0;
            else
                mem_count_n = mem_count_r + 1;
        end else
            mem_count_n = mem_count_r;
    end

    // consumed counter - dependent on handshake in only, for clarity
    // make sure shift, valid_o, ready_o are properly dependent on each other depending on state
    always_comb begin
        if (((ps_e == eSHIFT_IN) && valid_i) || (ps_e == eFULL && shift)) begin
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
    // NOTE: Need to avoid combinational loops here. Be sure to ONLY depend on handshake_out_en, valid_i
    //       ready_i, ps_e, even if it makes for longer expressions. This only enables valid_o, let the handshakes
    //       deal with timing and synchronization
    logic valid_o_enable;
    logic [$clog2(KERNEL_WIDTH+1)-1:0] handshake_in_count_r, handshake_in_count_n;
    assign valid_o_enable = handshake_in_count_r == '0 && valid_i;
    always_comb begin
        if (shift) begin
            if (handshake_in_count_r == KERNEL_WIDTH - 1)
                handshake_in_count_n = '0;
            else
                handshake_in_count_n = handshake_in_count_r + 1;
        end else begin
            handshake_in_count_n = handshake_in_count_r;
        end
    end
    
    always_ff @(posedge clk_i) begin
        if (reset_i || (ps_e != eFULL))
            handshake_in_count_r <= '0;
        else
            handshake_in_count_r <= handshake_in_count_n;    
    end

    // output address counter
    logic [$clog2(KERNEL_HEIGHT+1)-1:0] output_addr_r, output_addr_n;
    always_comb begin
        if (valid_o && ready_i) begin
            if (output_addr_r == KERNEL_HEIGHT)
                output_addr_n = '0;
            else
                output_addr_n = output_addr_r + 1;
        end else begin
            output_addr_n = output_addr_r;
        end
    end

    always_ff @(posedge clk_i) begin
        if (reset_i || ps_e == eREADY)
            output_addr_r <= '0;
        else
            output_addr_r <= output_addr_n;
    end

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
                shift = valid_i;
                valid_o = 1'b0;
            end
            eFULL: begin// this gets tricky, since it depends on handshake_out_en too
                shift = (valid_o_enable && valid_i && ready_i) || (!valid_o_enable && valid_i);
                valid_o = valid_o_enable && ready_i && valid_i;
                yumi_o = (valid_o_enable && valid_i && ready_i) || (!valid_o_enable && valid_i);
            end
            eSHIFT_OUT_1: begin
                yumi_o = 1'b0;
                if (KERNEL_WIDTH == 1) begin
                    valid_o = ready_i;
                    shift = ready_i;
                end else begin
                    valid_o = 1'b0;
                    shift = 1'b1;
                end
            end
            eSHIFT_OUT_2: begin // always handshake out on this state
                yumi_o = 1'b0;
                valid_o = ready_i;
                shift = ready_i; // shouldn't matter but have here to avoid inferring a latch
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

    `ifndef VIVADO
    logic [2**RAM_SELECT_BITS-1:0] mem_wen_select;
    assign mem_wen_select = w_en_i << w_addr_i[RAM_ADDRESS_BITS+RAM_SELECT_BITS-1:RAM_SELECT_BITS];
    `endif

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
           `ifdef VIVADO
            assign mem_addr_li = mem_count_n;            
           `else
           logic [2**RAM_SELECT_BITS-1:0] w_en_li;
           assign w_en_li = (w_en_i << (w_addr_i[RAM_SELECT_BITS+RAM_ADDRESS_BITS-1:RAM_ADDRESS_BITS]));
            assign mem_addr_li = mem_wen_select[i] ? w_addr_i[RAM_ADDRESS_BITS-1:0] : mem_count_n;
           `endif

            ROM_neuron #(
                .depth($clog2(KERNEL_SIZE+1)),
                .width(WORD_SIZE),
                .neuron_type(0),
                .layer_number(LAYER_NUMBER),
                .neuron_number(i)
            ) weight_mem (
                
               // compiler-dependent connection, uncomment if using VCS or if Vivado works properly
               `ifndef VIVADO
               .wen_i(w_en_li[i]),
               .data_i(w_data_i),
               `endif

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
                .reset_i(reset_i || (ps_e == eREADY) || (valid_o && ready_i && ~sum_en_li)),

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
                    .reset_i(reset_i || (ps_e == eREADY) || (shift && !shift_sum_en_lo[shift_register_index])),

                    .data_o(alu_data_lo[i][j+1])
            );
            end

            // assign output data
            assign data_o[WORD_SIZE*i+WORD_SIZE-1:i*WORD_SIZE] = alu_data_lo[i][output_addr_r];
        end
    endgenerate
endmodule