/**
Alex Knowlton
2/18/2023

1 Node for a convolutional neural network layer. All number are signed, output passed through ReLU
function before sent to output.

Parameters:
KERNEL_WIDTH    :   width of input kernel, default 2
KERNEL_HEIGHT   :   height of input kernel, default 3
WORD_SIZE       :   size of word to use, default 16

Inputs:
data_i  :   [KERNEL_HEIGHT-1:0][KERNEL_WIDTH-1:0][WORD_SIZE-1:0]    : input data
kernel_i:   [KERNEL_HEIGHT-1:0][KERNEL_WIDTH-1:0][WORD_SIZE-1:0]    : input kernel
bias_i  :   [WORD_SIZE-1:0] : input bias
start_i :   input start signal
clk_i   :   input clock
reset_i :   reset signal

Outputs:
data_o  :   [WORD_SIZE-1:0] output data
done_o  :   done signal for handshaking with control logic

*/

module conv_node #(
    parameter KERNEL_WIDTH=2,
    parameter KERNEL_HEIGHT=3,
    parameter WORD_SIZE=16) (
    input logic [KERNEL_HEIGHT-1:0][KERNEL_WIDTH-1:0][WORD_SIZE-1:0] data_i,
    input logic [KERNEL_HEIGHT-1:0][KERNEL_WIDTH-1:0][WORD_SIZE-1:0] kernel_i,
    input logic [WORD_SIZE-1:0] bias_i,
    input logic start_i,
    input logic clk_i,
    input logic reset_i,
    output logic [WORD_SIZE-1:0] data_o,
    output logic done_o);
    
    logic sum_bias_li, sum_done_li;
    
    conv_node_datapath #(
        .KERNEL_WIDTH(KERNEL_WIDTH), 
        .KERNEL_HEIGHT(KERNEL_HEIGHT),
        .WORD_SIZE(WORD_SIZE)) data (
        .data_i,
        .kernel_i,
        .bias_i,
        .done_i(done_o),
        .start_i,
        .clk_i,
        .reset_i,
        .sum_bias_i(sum_bias_li),
        .sum_done_o(sum_done_li),
        .data_o   
    );
    
    conv_node_control control (
        .clk_i,
        .reset_i,
        .start_i,
        .sum_done_i(sum_done_li),
        .sub_bias_o(sum_bias_li),
        .done_o
    );

endmodule

module conv_node_datapath #(
    parameter KERNEL_WIDTH=2,
    parameter KERNEL_HEIGHT=3,
    parameter WORD_SIZE=16) (
    input logic [KERNEL_HEIGHT-1:0][KERNEL_WIDTH-1:0][WORD_SIZE-1:0] data_i,
    input logic [KERNEL_HEIGHT-1:0][KERNEL_WIDTH-1:0][WORD_SIZE-1:0] kernel_i,
    input logic [WORD_SIZE-1:0] bias_i,
    input logic done_i,
    input logic start_i,
    input logic clk_i,
    input logic reset_i,
    input logic sum_bias_i,
    output logic sum_done_o,
    output logic [WORD_SIZE-1:0] data_o
);

    logic [11:0] row, col;

    always_ff @(posedge clk_i) begin
        if (start_i) begin
            row <= '0;
            col <= '0;
        end else if (sum_done_o) begin
            row <= row;
            col <= col;
        end else if (col == KERNEL_WIDTH - 1) begin
            row <= row + 1;
            col <= '0;
        end else begin
            row <= row;
            col <= col + 1;
        end
    end

    assign sum_done_o = (row == KERNEL_HEIGHT - 1) && (col == KERNEL_WIDTH - 1);

    // running sum logic with overflow
    logic [WORD_SIZE*2-1:0] current_sum_r, current_sum_n;
    // flag only used for output, not for sum
    logic overflow, overflow_flag; // overflow combinational, flag persistent
    
    // transition logic, reset at start
    always_ff @(posedge clk_i) begin
        if (start_i)
            current_sum_r <= '0;
        else
            current_sum_r <= current_sum_n;
    end
    
    always_comb begin
        if (done_i)
            current_sum_n = current_sum_r;
        else if (sum_bias_i)
            current_sum_n = current_sum_r - bias_i;
        else
            current_sum_n = current_sum_r + kernel_i[row][col] * data_i[row][col];
    end
    
    // overflow logic
    assign overflow = current_sum_n[WORD_SIZE*2-1:WORD_SIZE-2] != 0;
    
    always_ff @(posedge clk_i) begin
        if (start_i)
            overflow_flag <= 1'b0;
        else if (overflow)
            overflow_flag <= 1'b1;
        else
            overflow_flag <= overflow_flag;
    end
    
    // output logic
    always_ff @(posedge clk_i) begin
        if (start_i & overflow_flag) begin
            data_o[WORD_SIZE-2:0] = '1;
            data_o[WORD_SIZE-1] = 1'b0;
        end else if (start_i & current_sum_r[WORD_SIZE-1]) begin // ReLU function
            data_o <= '0;
        end else if (start_i) begin
            data_o <= current_sum_r[WORD_SIZE-1:0];
        end else
            data_o <= data_o;
    end
    
endmodule

module conv_node_control (
    input logic clk_i,
    input logic reset_i,
    input logic start_i,
    input logic sum_done_i,
    output logic sub_bias_o,
    output logic done_o
);

    enum {READY, SUMMING, BIAS} ps, ns;
    
    always_comb begin
        case (ps)
            READY:
                if (start_i)
                    ns = SUMMING;
                else
                    ns = READY;
            SUMMING:
                if (sum_done_i)
                    ns = BIAS;
                else
                    ns = SUMMING;
            BIAS: 
                ns = READY;
        endcase
    end
    
    always_ff @(posedge clk_i) begin
        if (reset_i)
            ps <= READY;
        else
            ps <= ns;
    end
    
    // assign outputs
    assign done_o = ps == READY;
    assign sub_bias_o = ps == BIAS;

endmodule