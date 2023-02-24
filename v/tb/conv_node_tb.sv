module conv_node_tb ();
    
    logic [2:0][1:0][15:0] data_i;
    logic [2:0][1:0][15:0] kernel_i;
    logic [15:0] bias_i, data_o;
    logic start_i, clk_i, reset_i, done_o;
    
    conv_node DUT (
        .data_i,
        .kernel_i,
        .bias_i,
        .start_i,
        .clk_i,
        .reset_i,
        .data_o,
        .done_o
    ); 
    
    // test data
    logic [2:0][1:0][15:0] test_data_1, test_data_2;
    assign kernel_i[0] = 32'h00010002;
    assign kernel_i[1] = 32'h00030004;
    assign kernel_i[2] = 32'h00050006;
    
    assign test_data_1[0] = 32'h00020004;
    assign test_data_1[1] = 32'h00030005;
    assign test_data_1[2] = 32'h00070009;
    
    assign test_data_2[0] = 32'h00010001;
    assign test_data_2[1] = 32'h00020001;
    assign test_data_2[2] = 32'h00060008;
    
    assign bias_i = 16'h000a;
    
    parameter CLOCK_PERIOD = 100;
    initial begin
        clk_i = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk_i = ~clk_i;
    end
    
    initial begin
        data_i <= test_data_1;
        reset_i <= 1'b1; @(posedge clk_i);
        reset_i <= 1'b0;
        start_i <= 1'b1; @(posedge clk_i);
        start_i <= 1'b0; repeat(8) @(posedge clk_i);
        data_i <= test_data_2; @(posedge clk_i);
        start_i <= 1'b1; @(posedge clk_i);
        start_i <= 1'b0; repeat(8) @(posedge clk_i);
        start_i <= 1'b1; @(posedge clk_i);
        start_i <= 1'b0; @(posedge clk_i);
        
        #20000
        $stop;
    end
endmodule