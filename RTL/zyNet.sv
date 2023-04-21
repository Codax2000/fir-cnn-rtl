module zyNet #(
    // small parameters for testing, increase for real scenario
    parameter NUM_SAMPLES=60,
    parameter KERNEL_WIDTH=2,
    parameter KERNEL_HEIGHT=5,
    parameter NUM_KERNELS=3,
    parameter HIDDEN_LAYER_HEIGHT=5,
    parameter OUTPUT_LAYER_HEIGHT=3
    parameter WORD_SIZE=16,
    parameter INT_BITS=8
) (
    input logic clk_i,
    input logic reset_i,

    input logic [WORD_SIZE-1:0] tx_data_i,
    input logic [WORD_SIZE-1:0] rx_data_i,

    input logic start_i,

    // output: helpful valid-ready handshake
    output logic [OUTPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] data_o,
    output logic valid_o,
    input logic yumi_i
);

genvar i
generate
    for (i = 0; i < NUM_KERNELS; i = i + 1) begin
        
        conv_layer #(/* TODO: insert parameters */
        
        ) kernel (
            /* TODO: insert input/outputs */
        );
        
        fc_output_layer #(
            /* TODO: Insert params */
        ) serializer (
            /* TODO: insert IO */
        );
        
        sub_layer #(
            /* TODO: Insert params */
        ) subtract_rx (
            /* TODO: insert IO */
        );

        abs_layer #(
            // TODO: insert params
        ) absolute_value (
            // TODO: insert IO
        );

        gap_layer #(
            // TODO: insert params
        ) global_average_pooling (
            // TODO: insert io
        );
    end
endgenerate

fc_layer #(
    // TODO: Insert params
) hidden_layer (
    // TODO: insert values
);

fc_output_layer #(
    // TODO: insert params
) hidden_layer_output (
    // TODO: insert values
);

bn_layer #(
    // TODO: insert params
) batch_normalize (
    // TODO: insert IO
)

relu_layer #(
    // TODO: insert params
) hidden_layer_relu (
    // TODO: insert values
);

double_fifo #(
    // TODO: Insert params
) hidden_layer_to_output_fifo (
    // TODO: insert values
);

fc_layer #(
    // TODO: insert params
) output_layer (
    // TODO: insert IO
);



endmodule