module fc_node_tb # ();

    logic [3:0][15:0] data_i;
    logic clk_i;
    logic reset_i;
    logic start_i;
    logic [15:0] data_o;
    logic done_o;
    
    fc_node DUT (.*);
    
    logic [3:0][15:0] test_data_1, test_data_2;
    
    assign test_data_1 = 64'h0001000200030004;
    assign test_data_2 = 64'h0005001000300015;
    
    parameter CLOCK_PERIOD = 100;
    initial begin
        clk_i = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk_i = ~clk_i;
    end
    
    initial begin
        data_i <= test_data_1;
        start_i <= 1'b0;
        reset_i <= 1'b1; @(posedge clk_i);
        reset_i <= 1'b0; @(posedge clk_i);
        start_i <= 1'b1; @(posedge clk_i);
        start_i <= 1'b0; repeat(5) @(posedge clk_i);
        start_i <= 1'b1; @(posedge clk_i);
        start_i <= 1'b0;
        data_i <= test_data_2; repeat(6) @(posedge clk_i);
        start_i <= 1'b1; @(posedge clk_i);
        data_i <= test_data_1; @(posedge clk_i);
        $stop;
    end
    
endmodule