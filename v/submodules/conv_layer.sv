/**
Alex Knowlton
2/28/2023

Convolutional layer module. Outputs done when all layers finished and biased. On start,
updates output and begins convolution again, assumed inputs are constant.
*/

module conv_layer #(
    parameter INPUT_LAYER_HEIGHT=4,
    parameter KERNEL_HEIGHT=3,
    parameter KERNEL_WIDTH=2,
    parameter WORD_SIZE=16) (
    input logic [INPUT_LAYER_HEIGHT-1:0][KERNEL_WIDTH-1:0][WORD_SIZE-1:0] data_i,
    input logic clk_i,
    input logic reset_i,
    input logic start_i,
    output logic done_o,
    output logic [INPUT_LAYER_HEIGHT - KERNEL_HEIGHT - 1:0][WORD_SIZE-1:0] data_o);
    
    // start and done determined by top-level CNN model
    
    // states for FSM
    enum {READY=2'b00, CONV=2'b01, BIAS=2'b10} ps, ns;

    logic [$clog2(KERNEL_HEIGHT+1)-1:0] kernel_row;
    logic [$clog2(KERNEL_WIDTH+1)-1:0] kernel_col;
    logic [$clog2(INPUT_LAYER_HEIGHT+1)-1:0] bias_index;

    logic [WORD_SIZE-1:0] bias_val, kernel_val;

    // // TODO: instantiate synchronous memory later, goes like this:
    ROM #(.width(WORD_SIZE),
          .depth(INPUT_LAYER_HEIGHT),
          .init_file("../mem/bias_mem_input.mem")) bias_rom (
            .clk_i,
            .reset_i,
            .addr_i(bias_index),
            .data_o(bias_val)
          );
    
    ROM #(.width(WORD_SIZE),
          .depth(KERNEL_HEIGHT * KERNEL_WIDTH),
          .init_file("../mem/kernel_mem_input.mem")) kernel_rom (
            .clk_i,
            .reset_i,
            .addr_i({kernel_row << $clog2(KERNEL_WIDTH), kernel_col}), // figure out how indexing works later
            .data_o(kernel_val)
          );

    always_comb begin
        case (ps)
            READY:
                if (start_i)
                    ns = CONV;
                else
                    ns = READY;
            CONV:
                if (kernel_row == KERNEL_HEIGHT && kernel_col == KERNEL_WIDTH)
                    ns = BIAS;
                else
                    ns = CONV;
            BIAS:
                if (bias_index == INPUT_LAYER_HEIGHT)
                    ns = READY;
                else
                    ns = BIAS;
        endcase
    end

    always_ff @(posedge clk_i) begin
        if (reset_i)
            ps <= READY;
        else
            ps <= ns;
    end

    // bias counter
    always_ff @(posedge clk_i) begin
        if (ps == BIAS)
            bias_index <= bias_index + 1;
        else
            bias_index <= '0;
    end

    // kernel row and column counters
    // iterate column first, then row
    logic row_done, col_done;
    assign row_done = row == KERNEL_HEIGHT;
    assign col_cone = col == KERNEL_WIDTH;

    always_ff @(posedge clk_i) begin
        if (ps != CONV) begin
            kernel_row <= '0;
            kernel_col <= '0;
        end else if (row_done && col_done) begin // should never enter this case, but good to have regardless
            kernel_row <= '0;
            kernel_col <= '0;
        end else if (col_done) begin
            kernel_row <= kernel_row + 1;
            kernel_col <= '0;
        end else begin
            kernel_row <= kernel_row;
            kernel_col <= kernel_col + 1;
        end
    end

    // generate convolutional nodes
    genvar i;
    generate
        for (i = 0; i < INPUT_LAYER_HEIGHT - KERNEL_HEIGHT - 1; i = i + 1) begin
            conv_node #(.WORD_SIZE(WORD_SIZE),
                        .KERNEL_HEIGHT(KERNEL_HEIGHT),
                        .KERNEL_WIDTH(KERNEL_WIDTH)) node (
                        .data_i(data_i[i+KERNEL_HEIGHT-1:i]),
                        .kernel_i(kernel_val),
                        .bias_i(bias_val),
                        .row_i(kernel_row),
                        .col_i(kernel_col),
                        .bias_en_i(1 << bias_index), // decoded bias index
                        .add_en_i(ps == CONV),
                        .done_en_i(start_i),
                        .clk_i,
                        .reset_i,
                        .data_o(data_o[i]));
        end
    endgenerate
endmodule