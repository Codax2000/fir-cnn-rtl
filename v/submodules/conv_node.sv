/**
Alex Knowlton
2/18/2023

1 Node for a convolutional neural network layer. All number are signed, output passed through ReLU
function before sent to output.
*/

module conv_node #(
    parameter WORD_SIZE=16,
    parameter KERNEL_HEIGHT=3,
    parameter KERNEL_WIDTH=2) (
    input logic clk_i,
    input logic reset_i,
    
    // control signal from top
    input logic start_i,
    input logic ps,

    input logic [KERNEL_HEIGHT-1:0][KERNEL_WIDTH-1:0][WORD_SIZE-1:0] data_i,
    input logic [WORD_SIZE-1:0] weight_i,

    input logic [$clog2(KERNEL_HEIGHT * KERNEL_WIDTH + 1)-1:0] input_index,
    input logic add_bias,

    output logic [WORD_SIZE-1:0] data_o
    );
    
    // transpose input data into one vector
    logic [KERNEL_HEIGHT * KERNEL_WIDTH - 1:0][WORD_SIZE-1:0] data_transpose;

    integer row, col;
    always_comb begin
        for (row = 0; row < KERNEL_HEIGHT; row = row + 1) begin
            for (col = 0; col < KERNEL_WIDTH; col = col + 1) begin
                data_transpose[col * KERNEL_WIDTH + row] = data_i[row][col];
            end
        end
    end
    
    // overflow logic - overflow_flag is persistent and used for saturating output, overflow is just combinational
    logic overflow, underflow, overflow_flag, underflow_flag;
    logic extra_bit;
    logic [WORD_SIZE * 2 - 1:0] mult_result;
    logic [WORD_SIZE - 1:0] sum_n, sum_r;

    assign mult_result = data_transpose * weight_i;
    assign adder_in = add_bias ? weight_i : mult_result[WORD_SIZE - 1:0];
    assign {extra_bit, sum_n} = data_transpose[input_index] + adder_in;

    assign overflow = (extra_bit ^ sum_n[WORD_SIZE-1]) || // overflow on adder
                      (~add_bias && ((mult_result[WORD_SIZE*2-1:WORD_SIZE] == '0) || (~mult_result[WORD_SIZE*2-1:WORD_SIZE] == '1))); // primitive overflow on multiplier

    assign overflow  = ({extra_bit, sum_n[WORD_SIZE-1]} == 2'b01); // TODO: add multiplier overflow/underflow
    assign underflow = ({extra_bit, sum_n[WORD_SIZE-1]} == 2'b10);

    // set overflow
    always_ff @(posedge clk_i) begin
        if (start_i) begin
            overflow_flag <= 1'b0;
            underflow_flag <= 1'b0;
        end else begin
            if (overflow)
                overflow_flag <= 1'b1;
            else
                overflow_flag <= overflow_flag;
            if (underflow)
                underflow_flag <= 1'b1;
            else
                underflow_flag <= underflow_flag;
        end
    end

    // output registers
    always_ff @(posedge clk_i) begin
        if (start_i || reset_i) begin
            sum_r <= '0;
        end else begin
            sum_r <= sum_n;
        end
    end

    always_ff @(posedge clk_i) begin
        if (reset_i)
            data_o <= '0;
        else if (add_bias && overflow_flag)
            data_o <= {1'b0, '1};
        else if (add_bias && (underflow_flag || sum_n[WORD_SIZE-1])) // ReLU function
            data_o <= '0;
        else
            data_o <= sum_n;
    end

endmodule

