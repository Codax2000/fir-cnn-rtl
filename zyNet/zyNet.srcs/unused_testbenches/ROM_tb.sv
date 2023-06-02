`timescale 1ns / 1ps

module ROM_tb ();

    logic clk_i, reset_i;
    logic [2:0] addr_i;
    logic [7:0] data_o;

    logic [3:0] x;
    logic [3:0] y;
    logic [7:0] product;
    
    assign x = 4'b0111;
    assign y = 4'h7;
    assign product = x * y;

    parameter CLOCK_PERIOD = 100;
    
    initial begin
        clk_i = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk_i = ~clk_i;
    end

    ROM_neuron #(
        .depth(3), 
        .width(8),
        .neuron_type(4),
        .layer_number(3),
        .neuron_number(146)
    ) DUT (.*);

    integer i;
    initial begin
        addr_i <= '0;
        reset_i <= 1'b1; @(posedge clk_i);
        reset_i <= 1'b0; @(posedge clk_i);
        for (i = 0; i < 8; i = i + 1) begin
            addr_i <= i;
            repeat(2)  @(posedge clk_i);
        end
        
        $stop;
    end

endmodule