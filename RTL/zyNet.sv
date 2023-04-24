module zyNet #(
    // small parameters for testing, increase for real scenario
    parameter WORD_SIZE=16,
    parameter INT_BITS=4
    ) (
    input logic clk_i,
    input logic reset_i,

    input logic [WORD_SIZE-1:0] data_i,
    input logic start_i,

    // output: helpful valid-ready handshake
    output logic [5-1:0][WORD_SIZE-1:0] data_o,
    output logic valid_o,
    input logic yumi_i);
    
    
    
    
    
// conv_layer_0
    localparam INPUT_LAYER_HEIGHT_0 = 16;
    localparam KERNEL_HEIGHT_0 = 4;
    localparam KERNEL_WIDTH_0 = 2;
    localparam NUM_KERNELS = 8;
    
    logic signed [NUM_KERNELS-1:0][INPUT_LAYER_HEIGHT_0 - KERNEL_HEIGHT_0:0][WORD_SIZE-1:0] conv0_data_lo;
    logic [NUM_KERNELS-1:0] conv0_valid_lo;
    
    
    
// fc_output_layer_0
    localparam LAYER_HEIGHT_0 = INPUT_LAYER_HEIGHT_0 - KERNEL_HEIGHT_0 + 1;
    
    logic [NUM_KERNELS-1:0] fc_output0_ready_lo, fc_output0_wen_lo;
    logic signed [NUM_KERNELS-1:0] [WORD_SIZE-1:0] fc_output0_data_lo;
    
    
    
// abs_layer_0
    logic [NUM_KERNELS-1:0] abs0_ready_lo, abs0_valid_lo;
    logic signed [NUM_KERNELS-1:0] [WORD_SIZE-1:0] abs0_data_lo;
    
    
    
// gap_layer_0
    logic [NUM_KERNELS-1:0] gap0_ready_lo, gap0_valid_lo;
    logic signed [NUM_KERNELS-1:0] [WORD_SIZE-1:0] gap0_data_lo;
    
    
    
// fc_output_layer_1
    localparam LAYER_HEIGHT_1 = 8;
    
    logic fc_output1_ready_lo, fc_output1_wen_lo;
    logic signed [WORD_SIZE-1:0] fc_output1_data_lo;
    
    
    
// double_fifo_0
    logic fifo0_full_lo, fifo0_empty_lo;
    logic signed [WORD_SIZE-1:0] fifo0_data_lo;
    
    
    
// fc_layer_0
    logic fc0_ren_lo, fc0_valid_lo;
    logic signed [NUM_KERNELS-1:0] [WORD_SIZE-1:0] fc0_data_lo;
    
    
    genvar i;
    generate
        for (i = 0; i < NUM_KERNELS; i = i + 1) begin
            conv_layer #(/* TODO: insert parameters */
                .INPUT_LAYER_HEIGHT(INPUT_LAYER_HEIGHT_0),
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
                .data_i,
                
                // helpful output interface
                .valid_o(conv0_valid_lo[i]),
                .yumi_i(fc_output0_ready_lo[i]),
                .data_o(conv0_data_lo[i])
            );


            fc_output_layer #(
                .LAYER_HEIGHT(LAYER_HEIGHT_0),
                .WORD_SIZE(WORD_SIZE)
            ) serializer (
                .clk_i,
                .reset_i,
                
                .valid_i(conv0_valid_lo[i]),
                .ready_o(fc_output0_ready_lo[i]),
                .data_i(conv0_data_lo[i]),
            
                .wen_o(fc_output0_wen_lo[i]),
                .full_i(~abs0_ready_lo[i]),
                .data_o(fc_output0_data_lo[i])
            );


            abs_layer #(
                .WORD_SIZE(WORD_SIZE)
            ) absolute_value (
                // top level control
                .clk_i,
                .reset_i,
            
                // handshake to prev layer
                .ready_o(abs0_ready_lo[i]),
                .valid_i(fc_output0_wen_lo[i]),
                .data_r_i(fc_output0_data_lo[i]),
            
                // handshake to next layer
                .valid_o(abs0_valid_lo[i]),
                .ready_i(gap0_ready_lo[i]),
                .data_r_o(abs0_data_lo[i])
            );

    
            gap_layer #(
                .INPUT_SIZE(INPUT_LAYER_HEIGHT_0-KERNEL_HEIGHT_0+1),
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
    ) hidden_layer_output (
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
        .LAYER_HEIGHT(NUM_KERNELS),
        .PREVIOUS_LAYER_HEIGHT(LAYER_HEIGHT_1),
        .LAYER_NUMBER(0)
    ) hidden_layer (
        .reset_i,
        .clk_i,
    
        // helpful input interface
        .data_i(fifo0_data_lo),
        .empty_i(fifo0_empty_lo),
        .ren_o(fc0_ren_lo), // also yumi_o, but not using that convention here
    
        // helpful output interface
        .valid_o(fc0_valid_lo),
        .ready_i(1'b1),
        .data_o(fc0_data_lo),

        // input for back-propagation, not currently used
        .weight_i(),
        .mem_wen_i()
    );
    
    //fc_output_layer #(
    //    // TODO: insert params
    //) hidden_layer_output (
    //    // TODO: insert values
    //);
    
    //bn_layer #(
    //    // TODO: insert params
    //) batch_normalize (
    //    // TODO: insert IO
    //);
    
    //relu_layer #(
    //    // TODO: insert params
    //) hidden_layer_relu (
    //    // TODO: insert values
    //);
    
    //double_fifo #(
    //    // TODO: Insert params
    //) hidden_layer_to_output_fifo (
    //    // TODO: insert values
    //);
    
    //fc_layer #(
    //    // TODO: insert params
    //) output_layer (
    //    // TODO: insert IO
    //);
    
endmodule