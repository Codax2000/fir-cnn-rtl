module conv_node #(
    parameter WORD_SIZE=16,
    parameter KERNEL_HEIGHT=3,
    parameter KERNEL_WIDTH=4)(
    input logic clk_i,
    input logic reset_i,
    input logic [KERNEL_HEIGHT - 1:0][KERNEL_WIDTH - 1:0][WORD_SIZE - 1:0] kernel_i,
    input logic [KERNEL_HEIGHT - 1:0][KERNEL_WIDTH - 1:0][WORD_SIZE - 1:0] data_i,
    input logic [WORD_SIZE - 1:0] bias_i,
    output logic [WORD_SIZE - 1:0] data_o);
    
    logic [WORD_SIZE - 1:0] biased_sum;
    logic [WORD_SIZE - 1:0] out;
    
    // results matrix for multiplication
    logic [KERNEL_HEIGHT - 1:0][KERNEL_WIDTH - 1:0][WORD_SIZE - 1:0] mult_result;
    logic [KERNEL_HEIGHT - 1:0][KERNEL_WIDTH - 1:0][WORD_SIZE-1:0] row_sum;
    logic [KERNEL_HEIGHT - 1:0][WORD_SIZE-1:0] sum;
    
    // assume no overflow in multiplication for now
    always_comb begin
        for (integer i = 0; i < KERNEL_HEIGHT; i = i + 1) begin
            for (integer j = 0; j < KERNEL_WIDTH; j = j + 1) begin
                mult_result[i][j] = data_i[i][j] * kernel_i[i][j];
            end
        end
        
        // summation
        for (integer i_sum = 0; i_sum < KERNEL_HEIGHT; i_sum = i_sum + 1) begin
            row_sum[i_sum][0] = mult_result[i_sum][0];
            for (integer j_sum = 1; j_sum < KERNEL_WIDTH; j_sum = j_sum + 1) begin
                row_sum[i_sum][j_sum] = row_sum[i_sum][j_sum - 1] + mult_result[i_sum][j_sum];
            end
        end
        
        sum[0] = row_sum[0][KERNEL_WIDTH - 1];
        for (integer z = 1; z < KERNEL_HEIGHT; z = z + 1) begin
            sum[z] = sum[z - 1] + row_sum[z][KERNEL_WIDTH - 1];
        end
    end  
    
    assign biased_sum = sum[KERNEL_HEIGHT - 1] - bias_i;
    always_comb begin
        if (biased_sum[WORD_SIZE - 1])
            out = '0;
        else
            out = biased_sum;
    end
    
    always_ff @(posedge clk_i) begin
        if (reset_i)
            data_o <= '0;
        else
            data_o <= out;
    end
        
    
endmodule
    