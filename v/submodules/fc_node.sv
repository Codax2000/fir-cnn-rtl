module fc_node #(
    parameter INPUT_HEIGHT=4,
    parameter WORD_SIZE=16,
    parameter LAYER_NUM=1, // number parameters used for memory initialization
    parameter NODE_NUM=1) (
    input logic [INPUT_HEIGHT-1:0][WORD_SIZE-1:0] data_i,
    input logic clk_i,
    input logic reset_i,
    input logic start_i, 
    output logic [WORD_SIZE-1:0] data_o,
    output logic done_o
);

    logic [WORD_SIZE - 1:0] mem_out;
    logic [$clog2(INPUT_HEIGHT+1)-1:0] mem_addr;

    // states and control signals for control
    enum {READY=1'b0, SUM=1'b1} ps, ns;
    logic add_bias, en_sum_update;

    ROM #(.width(WORD_SIZE),
          .depth(INPUT_HEIGHT + 1)) // add 1 for bias, since ROM holds bias in memory too
          .init_file("../../mem/fc_node_test.coe") mem (
          .clk_i,
          .reset_i,
          .addr_i(mem_addr),
          .data_o(mem_out);
    );

    logic [2*WORD_SIZE-1:0] weighted_data;
    assign weighted_data = data_i * mem_out;

    // logic for overflow
    logic overflow_flag, overflow_sum, overflow_mult;

    // TODO: this logic should be right but is untested
    assign overflow_mult = weighted_data[2*WORD_SIZE-1:WORD_SIZE-1] != '0;

    // TODO: assign overflow flag properly
    assign overflow_flag = 1'b0;

    logic [WORD_SIZE-1:0] sum_r, sum_n, sum_input;
    assign sum_input = add_bias ? mem_out : weighted_data[WORD_SIZE-1:0];

    sum_n = sum_r + sum_input;

    // control sum flip flop
    always_ff @(posedge clk_i) begin
        if (reset_i)
            sum_r <= '0;
        else if (en_sum_update)
            sum_r <= sum_n;
        else
            sum_r <= sum_r;
    end

    // control output register
    always_ff @(posedge clk_i) begin
        if (reset_i || (start_i && sum_r < 0))
            data_o <= '0;
        else if (start_i && sum_r > 0)
            data_o <= sum_r;
        else
            data_o <= data_o;
    end

endmodule