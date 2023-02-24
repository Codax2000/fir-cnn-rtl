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

    logic addr_eq_data_length, subtract_lo, add_lo;

    fc_node_control control (
        .start_i,
        .clk_i,
        .reset_i,
        .addr_eq_data_length,
        .done_o,
        .add_o(add_lo),
        .subtract_o(subtract_lo)
    );
        
    fc_node_datapath #(
        .INPUT_HEIGHT(INPUT_HEIGHT),
        .WORD_SIZE(WORD_SIZE),
        .LAYER_NUM(LAYER_NUM),
        .NODE_NUM(NODE_NUM)
        ) data (
        .clk_i,
        .reset_i,
        .data_i,
        .add_i(add_lo),
        .subtract_i(subtract_lo),
        .start_i,
        .data_o,
        .addr_eq_data_length
    );

endmodule

module fc_node_control (
    input logic clk_i,
    input logic reset_i,
    input logic addr_eq_data_length,
    output logic done_o,
    output logic add_o,
    output logic subtract_o,
    input logic start_i
);

    enum {READY, SUMMING, BIAS} ps, ns;

    // next state logic
    always_comb begin
        case (ps)
            READY:
                if (start_i)
                    ns = SUMMING;
                else
                    ns = READY;
            SUMMING:
                if (addr_eq_data_length)
                    ns = BIAS;
                else
                    ns = SUMMING;
            BIAS:
                ns = READY;
        endcase
    end

    // transition logic
    always_ff @(posedge clk_i) begin
        if (reset_i)
            ps <= READY;
        else
            ps <= ns;
    end

    assign done_o = ps == READY;
    assign add_o = ps == SUMMING;
    assign subtract_o = ps == BIAS;

endmodule

module fc_node_datapath #(
    parameter INPUT_HEIGHT=4, // input height should never be 1
    parameter WORD_SIZE=16,
    parameter LAYER_NUM=1, // number parameters used for memory initialization
    parameter NODE_NUM=1) (
    input logic clk_i,
    input logic reset_i,
    input logic [INPUT_HEIGHT-1:0][WORD_SIZE-1:0] data_i,
    input logic add_i,
    input logic subtract_i,
    input logic start_i,
    output logic [WORD_SIZE-1:0] data_o,
    output logic addr_eq_data_length
    );

    logic [WORD_SIZE*2-1:0] current_sum_r, current_sum_n;
    logic [$clog2(INPUT_HEIGHT):0] addr_r;
    
    // address logic
    always_ff @(posedge clk_i) begin
        if (reset_i | start_i)
            addr_r <= '0;
        else if (addr_r == INPUT_HEIGHT)
            addr_r <= addr_r;
        else
            addr_r <= addr_r + 1;
    end
    
    blk_mem_gen_0 weight_mem (
        .addra(addr_r),
        .douta(mem_out),
        .clka(clk_i)
    );
    logic [WORD_SIZE-1:0] mem_out;
    
    logic overflow, overflow_flag;

    // sum transitions
    always_ff @(posedge clk_i) begin
        if (start_i)
            current_sum_r <= '0;
        else
            current_sum_r <= current_sum_n;
    end

    // set next sum
    logic [2*WORD_SIZE-1:0] mem_out_se;
    sign_extend se (.val_i(mem_out), .val_o(mem_out_se));
    always_comb begin
        if (add_i)
            current_sum_n = current_sum_r + mem_out * data_i[addr_r];
        else if (subtract_i)
            current_sum_n = current_sum_r + mem_out_se; // subtract bias
        else
            current_sum_n = current_sum_r;
    end

    // set output data
    always_ff @(posedge clk_i) begin
        if (overflow_flag) begin
            data_o[WORD_SIZE-1] <= 1'b0;
            data_o[WORD_SIZE-2:0] <= '1;
        end else if (start_i)
            data_o <= current_sum_r;
        else
            data_o <= data_o;
    end

    // deal with overflow
    assign overflow = current_sum_n[WORD_SIZE*2-1:WORD_SIZE-2] != 0;

    always_ff @(posedge clk_i) begin
        if (start_i)
            overflow_flag <= 1'b0;
        else if (overflow)
            overflow_flag <= 1'b1;
        else
            overflow_flag <= overflow_flag;
    end
    
    assign addr_eq_data_length = addr_r == INPUT_HEIGHT;

endmodule