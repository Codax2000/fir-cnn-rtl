`timescale 1ns / 1ps

`include "include.v"

module Weight_Memory #(parameter numWeight = 3, neuronNo=5,layerNo=1,addressWidth=10,dataWidth=16,weightFile="w_1_15.mif") 
    ( 
    input clk,
    input wen,
    input ren,
    input [addressWidth-1:0] wadd,
    input [addressWidth-1:0] radd,
    input [dataWidth-1:0] win,
    output reg [dataWidth-1:0] wout);
    
    reg [dataWidth-1:0] mem [numWeight-1:0];        // numWeight array with dataWidth wide words 

    `ifdef pretrained                               // If pre-trained read weights from file "weightFile"
        initial
		begin
	        $readmemb(weightFile, mem);
	    end
	`else                                           // If NOT pre-trained
		always @(posedge clk)
		begin
			if (wen)                    // If wen add to the memory @wadd the weights comming as input
			begin
				mem[wadd] <= win;
			end
		end 
    `endif
    
    always @(posedge clk)
    begin
        if (ren)                                // If read enabled send out the weight located @radd
        begin
            wout <= mem[radd];
        end
    end 
endmodule