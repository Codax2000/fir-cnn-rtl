`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/24/2023 02:19:14 PM
// Design Name: 
// Module Name: toplevel_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module toplevel_tb();

    logic clk_i, reset_i;
    logic start_i;
    logic ready_o, start_o;
    
    logic clk_lower, reset_lower;
    
    localparam NUM_TESTS = 10;
    
    toplevel DUT (
        .clk_i,
        .reset_i,
        .begin_i(start_i)
    );
    
    assign clk_lower = DUT.clk_gen.clk_out1;
    assign reset_lower = DUT.reset_gen.bus_struct_reset;
    
    parameter CLOCK_PERIOD = 3.33333;
    
     
    // test values
    logic [159:0] expected_outputs [NUM_TESTS-1:0];
    initial $readmemh("test_outputs_measured.mif", expected_outputs);
    
    
    initial begin
        clk_i = 1'b0;
        forever #(CLOCK_PERIOD/2) clk_i = ~clk_i;
    end
    
    initial begin
        reset_i <= 1'b0;            @(posedge clk_i);
        reset_i <= 1'b1; repeat(16) @(posedge clk_i);
        reset_i <= 1'b0;            @(posedge clk_i);
    end
    
    initial begin
        start_i <= 1'b0; @(posedge clk_lower);
                         @(negedge reset_lower);
               repeat(4) @(posedge clk_lower);
        start_i <= 1'b1; repeat(20) @(posedge clk_lower);
        for (int i = 0; i < NUM_TESTS; i++) begin
            @(posedge DUT.cnn.valid_o);
            @(negedge clk_lower)
            $display("%t: Output: %h", $realtime, DUT.cnn_data_lo);
            assert(DUT.cnn_data_lo == expected_outputs[i])
                $display("%t: Test Case %d Passed", $realtime, i);
            else
                $display("%t: Test Case %h Failed. Expected %h, Received %h", $realtime, i, expected_outputs[i], DUT.cnn_data_lo);
            repeat(3) @(posedge clk_lower);
            start_i <= 1'b0; repeat(20) @(posedge clk_lower);
            start_i <= 1'b1; repeat(20) @(posedge clk_lower);
        end
        $stop;
    end

endmodule
