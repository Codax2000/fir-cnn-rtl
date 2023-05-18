`timescale 1ns / 1ps

`define SYNOPSIS
`ifndef SYNOPSIS
    `define VIVADO
`endif

module zyNet #(

    // small parameters for testing, increase for real scenario
    parameter WORD_SIZE=16,
    parameter INT_BITS=4,
    parameter OUTPUT_SIZE=10,
    
    parameter MEM_WORD_SIZE=21,
    parameter LAYER_SELECT_BITS=2,
    parameter RAM_SELECT_BITS=8,
    parameter RAM_ADDRESS_BITS=9) (
    
    // top level signals
    input logic clk_i,
    input logic reset_i,
    input logic start_i,
    
    // RAM write ports
    `ifdef SYNOPSIS
        input logic w_en_i,
        input logic [MEM_WORD_SIZE-1:0] w_data_i,
        input logic [LAYER_SELECT_BITS+RAM_SELECT_BITS+RAM_ADDRESS_BITS-1:0] w_addr_i,
    `endif
    
    // handshake to prev layer
    input logic [WORD_SIZE-1:0] data_i,
    input logic valid_i,
    output logic ready_o,

    // helpful handshake to next layer
    output logic [OUTPUT_SIZE*WORD_SIZE-1:0] data_o,
    output logic valid_o,
    input logic yumi_i);
    
    
    
    
    
// LAYER PARAMETERS AND WIRES

    // layer parameters
    localparam INPUT_LAYER_HEIGHT = 128; //128  16
    localparam KERNEL_HEIGHT_0 = 16; //16  4
    localparam KERNEL_WIDTH_0 = 2;
    localparam KERNEL_SIZE_0 = KERNEL_WIDTH_0*KERNEL_HEIGHT_0;
    localparam NUM_KERNELS = 256; //256  8
    localparam FC_LAYER_HEIGHT_0 = 256; // 256  8
    localparam FC_LAYER_HEIGHT_1 = 10;
    
    
    //  output ready values to avoid synthesis errors
    logic [NUM_KERNELS-1:0] ready_outs;
    assign ready_o = ready_outs[0];
    
    // conv_layer_0
    logic signed [NUM_KERNELS*WORD_SIZE-1:0] conv0_data_lo;
    logic [NUM_KERNELS-1:0] conv0_valid_lo;
    
    // abs_layer_0
    logic [NUM_KERNELS-1:0] abs0_ready_lo, abs0_valid_lo;
    logic signed [NUM_KERNELS*WORD_SIZE-1:0] abs0_data_lo;
    
    // gap_layer_0
    logic [NUM_KERNELS-1:0] gap0_ready_lo, gap0_valid_lo;
    logic signed [NUM_KERNELS*WORD_SIZE-1:0] gap0_data_lo;
    
    // fc_output_layer_1    
    logic fc_output1_ready_lo, fc_output1_wen_lo;
    logic signed [WORD_SIZE-1:0] fc_output1_data_lo;
    
    // double_fifo_0
    logic fifo0_full_lo, fifo0_empty_lo;
    logic signed [WORD_SIZE-1:0] fifo0_data_lo;
    
    // fc_layer_0    
    logic fc0_ren_lo, fc0_valid_lo;
    logic signed [FC_LAYER_HEIGHT_0*WORD_SIZE-1:0] fc0_data_lo;
    
    // fc_output_layer_2
    logic fc_output2_ready_lo, fc_output2_wen_lo;
    logic signed [WORD_SIZE-1:0] fc_output2_data_lo;
    
    // bn_layer_0
    logic bn0_ready_lo, bn0_valid_lo;
    logic signed [WORD_SIZE-1:0] bn0_data_lo;
    
    // relu_layer_0
    logic relu0_ready_lo, relu0_valid_lo;
    logic signed [WORD_SIZE-1:0] relu0_data_lo;
    
    
    
    
    
// MEM WRITE CONTROLLER
    `ifdef SYNOPSIS
        logic [LAYER_SELECT_BITS-1:0] w_en_li;
        assign w_en_li = (w_en_i << w_addr_i[RAM_SELECT_BITS+RAM_ADDRESS_BITS +: LAYER_SELECT_BITS]);
        
        logic [RAM_SELECT_BITS-1:0] ram_sel_li;
        assign ram_sel_li = w_addr_i[RAM_ADDRESS_BITS +: RAM_SELECT_BITS];
        
        logic [RAM_ADDRESS_BITS-1:0] ram_addr_li;
        assign ram_addr_li = w_addr_i[RAM_ADDRESS_BITS-1:0];
    `endif

    
    
    
    
// LAYER DATAPATH

    genvar i;
    generate
        for (i = 0; i < NUM_KERNELS; i = i + 1) begin
            conv_layer #(
                .INPUT_LAYER_HEIGHT(INPUT_LAYER_HEIGHT),
                .KERNEL_HEIGHT(KERNEL_HEIGHT_0),
                .KERNEL_WIDTH(KERNEL_WIDTH_0),
                .WORD_SIZE(WORD_SIZE),
                .INT_BITS(INT_BITS),
                .LAYER_NUMBER(0),
                .CONVOLUTION_NUMBER(i)
            ) kernel (
                .clk_i,
                .reset_i,
                .start_i,
                
                // memory interface
                `ifdef SYNOPSIS
                    .w_en_i(w_en_li[0]),
                    .w_data_i(w_data_i[WORD_SIZE]),
                    .w_addr_i({ram_sel_li[$clog2(NUM_KERNELS)-1:0],ram_addr_li[$clog2(KERNEL_SIZE_0+1)-1:0]}),
                `endif
                
                // handshake to prev layer
                .valid_i,
                .ready_o(ready_outs[i]),
                .data_i,
                
                // helpful handshake to next layer
                .valid_o(conv0_valid_lo[i]),
                .ready_i(abs0_ready_lo[i]),
                .data_o(conv0_data_lo[(i+1)*WORD_SIZE-1:i*WORD_SIZE])
            );


            abs_layer #(
                .WORD_SIZE(WORD_SIZE)
            ) absolute_value (
                // top level control
                .clk_i,
                .reset_i,
            
                // handshake to prev layer
                .ready_o(abs0_ready_lo[i]),
                .valid_i(conv0_valid_lo[i]),
                .data_r_i(conv0_data_lo[(i+1)*WORD_SIZE-1:i*WORD_SIZE]),
            
                // handshake to next layer
                .valid_o(abs0_valid_lo[i]),
                .ready_i(gap0_ready_lo[i]),
                .data_r_o(abs0_data_lo[(i+1)*WORD_SIZE-1:i*WORD_SIZE])
            );

    
            gap_layer #(
                .INPUT_SIZE(INPUT_LAYER_HEIGHT-KERNEL_HEIGHT_0+1),
                .WORD_SIZE(WORD_SIZE),
                .N_SIZE(WORD_SIZE-INT_BITS)
            ) global_average_pooling (
                // top level control
                .clk_i,
                .reset_i,
            
                // handshake to prev layer
                .ready_o(gap0_ready_lo[i]),
                .valid_i(abs0_valid_lo[i]),
                .data_r_i(abs0_data_lo[(i+1)*WORD_SIZE-1:i*WORD_SIZE]),
            
                // handshake to next layer
                .valid_o(gap0_valid_lo[i]),
                .ready_i(1'b1),
                .data_r_o(gap0_data_lo[(i+1)*WORD_SIZE-1:i*WORD_SIZE])
            );
        
        end
    endgenerate
    
    
    fc_output_layer #(
        .LAYER_HEIGHT(NUM_KERNELS),
        .WORD_SIZE(WORD_SIZE)
    ) fc_output_layer_1 (
        .clk_i,
        .reset_i,
        
        // handshake to prev layer
        .valid_i(&gap0_valid_lo),
        .ready_o(fc_output1_ready_lo),
        .data_i(gap0_data_lo),
    
        // handshake to next layer
        .wen_o(fc_output1_wen_lo),
        .full_i(fifo0_full_lo),
        .data_o(fc_output1_data_lo)
    );
    
    
    double_fifo #(
        .WORD_SIZE(WORD_SIZE)
    ) fifo_0 (
        .clk_i,
        .reset_i,
        
        // handshake to prev layer
        .full_o(fifo0_full_lo),
        .wen_i(fc_output1_wen_lo),
        .data_i(fc_output1_data_lo),
    
        // handshake to next layer
        .ren_i(fc0_ren_lo),
        .empty_o(fifo0_empty_lo),
        .data_o(fifo0_data_lo)
    );
    
    
    fc_layer #(
        .WORD_SIZE(WORD_SIZE),
        .INT_BITS(INT_BITS),
        .LAYER_HEIGHT(FC_LAYER_HEIGHT_0),
        .PREVIOUS_LAYER_HEIGHT(NUM_KERNELS),
        .LAYER_NUMBER(0)
    ) hidden_layer (
        .reset_i,
        .clk_i,
        
        // memory interface
        `ifdef SYNOPSIS
            .w_en_i(w_en_li[1]),
            .w_data_i(w_data_i[WORD_SIZE-1:0]),
            .w_addr_i({ram_sel_li[$clog2(FC_LAYER_HEIGHT_0)-1:0],ram_addr_li[$clog2(NUM_KERNELS+1)-1:0]}),
        `endif
        
        // demanding input interface
        .data_i(fifo0_data_lo),
        .empty_i(fifo0_empty_lo),
        .ren_o(fc0_ren_lo), // also yumi_o, but not using that convention here
    
        // helpful output interface
        .valid_o(fc0_valid_lo),
        .ready_i(fc_output2_ready_lo),
        .data_o(fc0_data_lo),

        // input for back-propagation, not currently used
        .weight_i('0),
        .mem_wen_i(1'b0)
    );
    
    
    fc_output_layer #(
        .LAYER_HEIGHT(FC_LAYER_HEIGHT_0),
        .WORD_SIZE(WORD_SIZE)
    ) fc_output_layer_2 (
        .clk_i,
        .reset_i,
        
        // handshake to prev layer
        .valid_i(fc0_valid_lo),
        .ready_o(fc_output2_ready_lo),
        .data_i(fc0_data_lo),
    
        // handshake to next layer
        .wen_o(fc_output2_wen_lo),
        .full_i(~bn0_ready_lo),
        .data_o(fc_output2_data_lo)
    );
    
    
    bn_layer #(
        .INPUT_SIZE(FC_LAYER_HEIGHT_0),
        .LAYER_NUMBER(0),
        .WORD_SIZE(WORD_SIZE),
        .N_SIZE(WORD_SIZE-INT_BITS),
        .MEM_WORD_SIZE(MEM_WORD_SIZE)
    ) bn_layer_0 (
        // top level control
        .clk_i,
        .reset_i,
        
        // memory interface
        `ifdef SYNOPSIS
            .w_en_i(w_en_li[2]),
            .w_data_i(w_data_i),
            .w_addr_i({ram_sel_li[$clog2(4)-1:0],ram_addr_li[$clog2(FC_LAYER_HEIGHT_0)-1:0]}),
        `endif
        
        // handshake to prev layer
        .ready_o(bn0_ready_lo),
        .valid_i(fc_output2_wen_lo),
        .data_r_i(fc_output2_data_lo),
        
        // handshake to next layer
        .valid_o(bn0_valid_lo),
        .ready_i(relu0_ready_lo),
        .data_r_o(bn0_data_lo)
    );
    
    
    relu_layer #(
        .WORD_SIZE(WORD_SIZE)
    ) hidden_layer_relu (
        // top level control
        .clk_i,
        .reset_i,
        
        // handshake to prev layer
        .ready_o(relu0_ready_lo),
        .valid_i(bn0_valid_lo),
        .data_r_i(bn0_data_lo),
        
        // handshake to next layer
        .valid_o(relu0_valid_lo),
        .ready_i(fc1_ren_lo),
        .data_r_o(relu0_data_lo)
    );

    
    fc_layer #(
        .WORD_SIZE(WORD_SIZE),
        .INT_BITS(INT_BITS),
        .LAYER_HEIGHT(FC_LAYER_HEIGHT_1),
        .PREVIOUS_LAYER_HEIGHT(FC_LAYER_HEIGHT_0),
        .LAYER_NUMBER(1)
    ) fc_layer_1 (
        .reset_i,
        .clk_i,
        
        // memory interface
        `ifdef SYNOPSIS
            .w_en_i(w_en_li[3]),
            .w_data_i(w_data_i[WORD_SIZE-1:0]),
            .w_addr_i({ram_sel_li[$clog2(FC_LAYER_HEIGHT_1)-1:0],ram_addr_li[$clog2(FC_LAYER_HEIGHT_0+1)-1:0]}),
        `endif
        
        // demanding input interface
        .data_i(relu0_data_lo),
        .empty_i(~relu0_valid_lo),
        .ren_o(fc1_ren_lo), // also yumi_o, but not using that convention here
    
        // helpful output interface
        .valid_o,
        .ready_i(yumi_i),
        .data_o,

        // input for back-propagation, not currently used
        .weight_i('0),
        .mem_wen_i(1'b0)
    );
    
endmodule