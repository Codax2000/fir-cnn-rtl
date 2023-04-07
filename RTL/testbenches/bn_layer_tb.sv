

module bn_layer_tb ();
    
    parameter CLOCK_PERIOD = 100;
    
    parameter INPUT_SIZE=2;
    parameter WORD_SIZE=8;
    parameter MEM_INIT_MEAN="mean_test.mif";
    parameter MEM_INIT_VARIANCE="variance_test.mif";
    parameter MEM_INIT_SCALE="scale_test.mif";
    parameter MEM_INIT_OFFSET="offset_test.mif";
    
// VARIABLES
    
    // input clock
    logic clk_i;
    initial begin
        clk_i = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk_i = ~clk_i;
    end
    
    logic reset_i;
    
    // handshake to prev layer
    logic ready_o;
    logic valid_i;
    logic signed [WORD_SIZE-1:0] data_r_i;
    
    // handshake to next layer
    logic valid_o;
    logic ready_i;
    logic signed [WORD_SIZE-1:0] data_r_o;
    
    
    
// DEVICE UNDER TEST
    bn_layer #(.INPUT_SIZE(INPUT_SIZE),
               .WORD_SIZE(WORD_SIZE),
               .MEM_INIT_MEAN(MEM_INIT_MEAN),
               .MEM_INIT_VARIANCE(MEM_INIT_VARIANCE),
               .MEM_INIT_SCALE(MEM_INIT_SCALE),
               .MEM_INIT_OFFSET(MEM_INIT_OFFSET)
    ) DUT (.*);
    
    
    
// TESTBENCH
    
    initial begin
        // reset
        reset_i <= 1; @(posedge clk_i); reset_i <= 0; @(posedge clk_i);
        
        // prev layer produces data
        valid_i <= 1;
        data_r_i  <= 8'b00010000;
        @(posedge clk_i)
        
        
        $stop;
    end
    
endmodule
