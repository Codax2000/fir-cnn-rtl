`timescale 1ns / 1ps

module bn_layer_tb ();
    
    parameter CLOCK_PERIOD = 10;
    
    parameter INPUT_SIZE=10;
    parameter WORD_SIZE=16;
    parameter MEM_INIT_MEAN="bn_mean_test.mif";
    parameter MEM_INIT_VARIANCE="bn_variance_test.mif";
    parameter MEM_INIT_SCALE="bn_scale_test.mif";
    parameter MEM_INIT_OFFSET="bn_offset_test.mif";
    
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
        ready_i <= 1;
        @(posedge clk_i)
        
        data_r_i  <= 16'b0011101101000110; @(posedge clk_i) // 0.732469473752462
        data_r_i  <= 16'b0000010111111110; @(posedge clk_i) // -0.621721030422373
        data_r_i  <= 16'b0000001010110101; @(posedge clk_i) // 0.773024276220328
        data_r_i  <= 16'b1101110110100101; @(posedge clk_i) // -0.917345614901317
        data_r_i  <= 16'b1111111010010100; @(posedge clk_i) // 0.251466403216965
        data_r_i  <= 16'b0000111111100001; @(posedge clk_i) // -0.535625366716028
        data_r_i  <= 16'b0001011011101110; @(posedge clk_i) // 1.08386757001342
        data_r_i  <= 16'b1111001010100000; @(posedge clk_i) // 0.560921617710491
        data_r_i  <= 16'b1110111100001000; @(posedge clk_i) // 0.113087525500705
        data_r_i  <= 16'b0011111001110110; @(posedge clk_i) // -0.107299784013662
        
        
        @(posedge clk_i)
        $stop;
    end
    
endmodule
