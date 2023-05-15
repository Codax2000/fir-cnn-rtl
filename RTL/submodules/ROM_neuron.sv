`timescale 1ns / 1ps
/**
Alex Knowlton
Single-port synchronous ROM

In Vivado, give name of init file, not relative path. Vivado will handle the relative pathing

parameters:
    depth: number of bits in address
    width: number of bits in output data
    neuron_type: 1 or 0, 1 for fully-connected, 0 for convolutional
    layer_number: layer identifier
    neuron number: neuron identifier

Added 5/14: compiler-dependent write data and write enable. TODO: implement using OpenRAM macro
*/

module ROM_neuron #(parameter depth=3, width=8, neuron_type=0, layer_number=1, neuron_number=0) (
    input   logic reset_i,
    input  logic clk_i,
    input  logic [depth-1:0] addr_i,
//    `ifndef VIVADO
//    input logic [width-1:0] data_i,
//    input logic wen_i,
//    `endif

    output logic [width-1:0] data_o
    );

    localparam ascii_offset = 48;
	localparam logic [7:0] neuron_type_p = neuron_type + ascii_offset;
    localparam logic [7:0] layer_number_p = layer_number + ascii_offset;
    localparam logic [7:0] neuron_number_ones_p = (neuron_number % 10) + ascii_offset;
    localparam logic [7:0] neuron_number_tens_p = ((neuron_number / 10) % 10) + ascii_offset;
    localparam logic [7:0] neuron_number_hundreds_p = ((neuron_number / 100) % 10) + ascii_offset;
    

    // odd logic, but it synthesizes to {"n_n_nnn.mem" where "n" is a parameter as defined above}
    localparam logic [87:0] init_file = {neuron_type_p, 8'h5f, layer_number_p, 8'h5f, neuron_number_hundreds_p, neuron_number_tens_p, neuron_number_ones_p, 32'h2e6d656d};

	ROM_inferred #(
        .ADDR_WIDTH(depth),
        .WORD_SIZE(width),
        .MEM_INIT(init_file)
    ) internal_rom (
        .addr_i,
        .data_o,
        .clk_i,
        .reset_i
    );
    
endmodule