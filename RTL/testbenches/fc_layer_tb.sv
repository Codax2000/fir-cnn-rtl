module fc_layer_tb ();

    logic clk_i, reset_i, valid_i, ready_o;
    logic [3:0][15:0] data_i;

    logic wen_o, full_i;
    logic [15:0] data_o, data_oo;
    logic empty_o, ren_i;

    fc_output_layer #(
        .WORD_SIZE(16),
        .LAYER_HEIGHT(4)
    ) DUT (.*);
    
    double_fifo fifo (
        .clk_i,
        .reset_i,
        .wen_i(wen_o),
        .ren_i,
        .data_i(data_o),

        .full_o(full_i),
        .empty_o(empty_o),
        .data_o(data_oo)
    );

    parameter CLOCK_PERIOD = 100;
    initial begin
        clk_i = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk_i = ~clk_i;
    end

    // manipulate ren_i, data_i, valid_i,
    initial begin
        data_i <= 64'h00af_0010_0514_0136;
        reset_i <= 1'b1; @(posedge clk_i);
        reset_i <= 1'b0; 
        valid_i <= 1'b1; @(posedge clk_i);
        valid_i <= 1'b0; @(posedge clk_i);
        ren_i <= 1'b1; @(posedge clk_i);
        ren_i <= 1'b0; repeat(2) @(posedge clk_i);
        ren_i <= 1'b1; repeat(4) @(posedge clk_i);
        
        $stop;
    end

endmodule