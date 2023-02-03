`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/02/2023 07:49:21 PM
// Design Name: 
// Module Name: blk_mem_gen_0_tb
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


module blk_mem_gen_0_tb();

    logic clk;
    logic [3:0] read_addr_li;
    logic [15:0] data_lo;
    
    blk_mem_gen_1 DUT (
        .clka(clk),
        .addra(read_addr_li),
        .douta(data_lo)
    );
    
    parameter CLOCK_PERIOD = 100;
    initial begin
        clk = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk = ~clk;
    end 
    
    initial begin
        #20; read_addr_li <= 4'h0; @(posedge clk);
        #20; read_addr_li <= 4'h2; @(posedge clk);
        #20; read_addr_li <= 4'h4; @(posedge clk);
        #20; read_addr_li <= 4'h8; @(posedge clk);
        
        #20; read_addr_li <= 4'h0; repeat(2) @(posedge clk);
        #20; read_addr_li <= 4'h3; repeat(6) @(posedge clk);
        $stop;
    end

endmodule
