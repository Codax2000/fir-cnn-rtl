`define VIVADO

module zyNet #(
    // small parameters for testing, increase for real scenario
    parameter WORD_SIZE=16,
    parameter INT_BITS=4,
    parameter OUTPUT_SIZE=10
    ) (
    input logic clk_i,
    input logic reset_i,

    input logic start_i,

    input logic [WORD_SIZE-1:0] data_i,
    input logic valid_i,
    output logic ready_o,

    // output: helpful valid-ready handshake
    output logic [OUTPUT_SIZE-1:0][WORD_SIZE-1:0] data_o,
    output logic valid_o,
    input logic yumi_i);
    
    
    // LAYER PARAMETERS AND WIRES

    // conv_layer_0
    localparam INPUT_LAYER_HEIGHT = 128; //128  16
    localparam KERNEL_HEIGHT_0 = 16; //16  4
    localparam KERNEL_WIDTH_0 = 2;
    localparam NUM_KERNELS = 256; //256  8
    localparam LAYER_HEIGHT_0 = INPUT_LAYER_HEIGHT - KERNEL_HEIGHT_0 + 1;
    localparam LAYER_HEIGHT_1 = NUM_KERNELS;
    localparam LAYER_HEIGHT_2 = 256; // 256  8
    localparam LAYER_HEIGHT_3 = OUTPUT_SIZE;
    
    //  output ready values to avoid synthesis errors
    logic [NUM_KERNELS-1:0] ready_outs;
    assign ready_o = ready_outs[0];
    
    
    logic signed [NUM_KERNELS-1:0][WORD_SIZE-1:0] conv0_data_lo;
    logic [NUM_KERNELS-1:0] conv0_valid_lo;
    
    
//    // fc_output_layer_0
//    logic [NUM_KERNELS-1:0] fc_output0_ready_lo, fc_output0_wen_lo;
//    logic signed [NUM_KERNELS-1:0] [WORD_SIZE-1:0] fc_output0_data_lo;
    
    
    // abs_layer_0
    logic [NUM_KERNELS-1:0] abs0_ready_lo, abs0_valid_lo;
    logic signed [NUM_KERNELS-1:0] [WORD_SIZE-1:0] abs0_data_lo;
    
    
    // gap_layer_0
    logic [NUM_KERNELS-1:0] gap0_ready_lo, gap0_valid_lo;
    logic signed [NUM_KERNELS-1:0] [WORD_SIZE-1:0] gap0_data_lo;
    
    
    // fc_output_layer_1    
    logic fc_output1_ready_lo, fc_output1_wen_lo;
    logic signed [WORD_SIZE-1:0] fc_output1_data_lo;
    
    
    // double_fifo_0
    logic fifo0_full_lo, fifo0_empty_lo;
    logic signed [WORD_SIZE-1:0] fifo0_data_lo;
    
    
    // fc_layer_0    
    logic fc0_ren_lo, fc0_valid_lo;
    logic signed [LAYER_HEIGHT_2-1:0] [WORD_SIZE-1:0] fc0_data_lo;
    
    
    // fc_output_layer_2
    logic fc_output2_ready_lo, fc_output2_wen_lo;
    logic signed [WORD_SIZE-1:0] fc_output2_data_lo;
    
    
    // bn_layer_0
    logic bn0_ready_lo, bn0_valid_lo;
    logic signed [WORD_SIZE-1:0] bn0_data_lo;
    
    
    // relu_layer_0
    logic relu0_ready_lo, relu0_valid_lo;
    logic signed [WORD_SIZE-1:0] relu0_data_lo;
    
    
    // fc_layer_1    
    logic fc1_ren_lo, fc1_valid_lo;
    logic signed [LAYER_HEIGHT_3-1:0] [WORD_SIZE-1:0] fc1_data_lo;
    
    
    
    
    
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
                
                // input interface
                .start_i,

                .valid_i,
                .ready_o(ready_outs[i]),
                .data_i,
                
                // helpful output interface
                .valid_o(conv0_valid_lo[i]),
                .ready_i(abs0_ready_lo[i]),
                .data_o(conv0_data_lo[i])
            );


//            fc_output_layer #(
//                .LAYER_HEIGHT(LAYER_HEIGHT_0),
//                .WORD_SIZE(WORD_SIZE)
//            ) fc_output_layer_0 (
//                .clk_i,
//                .reset_i,
                
//                .valid_i(conv0_valid_lo[i]),
//                .ready_o(fc_output0_ready_lo[i]),
//                .data_i(conv0_data_lo[i]),
            
//                .wen_o(fc_output0_wen_lo[i]),
//                .full_i(~abs0_ready_lo[i]),
//                .data_o(fc_output0_data_lo[i])
//            );


            abs_layer #(
                .WORD_SIZE(WORD_SIZE)
            ) absolute_value (
                // top level control
                .clk_i,
                .reset_i,
            
                // handshake to prev layer
                .ready_o(abs0_ready_lo[i]),
                .valid_i(conv0_valid_lo[i]),
                .data_r_i(conv0_data_lo[i]),
            
                // handshake to next layer
                .valid_o(abs0_valid_lo[i]),
                .ready_i(gap0_ready_lo[i]),
                .data_r_o(abs0_data_lo[i])
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
                .data_r_i(abs0_data_lo[i]),
            
                // handshake to next layer
                .valid_o(gap0_valid_lo[i]),
                .ready_i(1'b1),
                .data_r_o(gap0_data_lo[i])
            );
        
        end
    endgenerate
    
    
    fc_output_layer #(
        .LAYER_HEIGHT(LAYER_HEIGHT_1),
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
        .LAYER_HEIGHT(LAYER_HEIGHT_2),
        .PREVIOUS_LAYER_HEIGHT(LAYER_HEIGHT_1),
        .LAYER_NUMBER(0)
    ) hidden_layer (
        .reset_i,
        .clk_i,
    
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
        .LAYER_HEIGHT(LAYER_HEIGHT_2),
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
        .INPUT_SIZE(LAYER_HEIGHT_2),
        .LAYER_NUMBER(0),
        .WORD_SIZE(WORD_SIZE),
        .N_SIZE(WORD_SIZE-INT_BITS),
        .MEM_WORD_SIZE(WORD_SIZE+5)
    ) bn_layer_0 (
        // top level control
        .clk_i,
        .reset_i,
        
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
        .LAYER_HEIGHT(LAYER_HEIGHT_3),
        .PREVIOUS_LAYER_HEIGHT(LAYER_HEIGHT_2),
        .LAYER_NUMBER(1)
    ) fc_layer_1 (
        .reset_i,
        .clk_i,
    
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