module double_fifo_tb ();

    logic clk_i, reset_i, wen_i, ren_i;
    logic [15:0] data_i, data_o;

    logic full_o, empty_o;
    
    double_fifo DUT (.*);
    
    parameter CLOCK_PERIOD = 100;
    initial begin
        clk_i = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk_i = ~clk_i;
    end
    
    initial begin
        reset_i <= 1'b1; 
        data_i <= 4'ha;     @(posedge clk_i);
        
        // test behavior with one element
        reset_i <= 1'b0;
        wen_i <= 1'b1;      @(posedge clk_i);
        data_i <= 4'hf;
        ren_i <= 1'b1;      @(posedge clk_i);
        assert (data_o == 4'ha)
            else $display("Test 1 Assertion error: Expected %h, Received %h", 4'ha, data_o);

        wen_i <= 1'b0;      @(posedge clk_i);
        assert (data_o == 4'hf)
            else $display("Test 2 Assertion error: Expected %h, Received %h", 4'hf, data_o);

        ren_i <= 1'b0;      @(posedge clk_i);
        assert (empty_o)
            else $display("Test 3 Assertion error: FIFO should be empty");

        // test behavior with two elements
        data_i <= 4'h9;
        wen_i <= 1'b1;      @(posedge clk_i);
        
        data_i <= 4'h4;
        @(posedge clk_i);
        ren_i <= 1'b1;
        data_i <= 4'h7;
        assert (data_o == 4'h9)
            else $display("Test 4 Assertion error: Expected %h, Received %h", 4'h9, data_o);

        @(posedge clk_i);
        ren_i <= 1'b0;
        wen_i <= 1'b0;
        data_i <= 4'h2;
        
        @(posedge clk_i);
        assert (full_o)
            else $display("Test 5 Assertion error: FIFO should be full");
        assert (data_o == 4'h4)
            else $display("Test 6 Assertion error: Expected %h, Received %h", 4'h4, data_o);
        
        ren_i <= 1'b1; repeat(2) @(posedge clk_i);
        assert (data_o == 4'h7)
            else $display("Test 7 Assertion error: Expected %h, Received %h", 4'h7, data_o);

        ren_i <= 1'b0;
        @(posedge clk_i);
        assert (empty_o)
            else $display("Test 8 Assertion error: FIFO should be empty");

        $stop;
    end
    

endmodule