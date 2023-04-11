`timescale 1ns / 1ps

/**
Eugene Liu
4/4/2023

ReLU layer. Sequentially applies a max(0,x) function to inputs

Interface: Uses valid-ready handshakes. Is a helpful producer and consumer. The data_r_i is expected to come directly from a register, and data_r_o comes directly from a register.
Implementation: Interperts the MSB as the sign bit and sets negative inputs to 0. Contains a single register.

parameters:
  WORD_SIZE : the number of bits of inputs/outputs

input-outputs:
  clk_i    : input clock
  reset_i  : reset signal. Resets controller only, data_r_o remains the same.

  ready_o  : handshake to prev layer. Indicates this layer is ready to recieve
  valid_i  : handshake to prev layer. Indicates prev layer has valid data
  data_r_i : handshake to prev layer. The data from the prev layer to this layer

  valid_o  : handshake to next layer. Indicates this layer has valid data
  ready_i  : handshake to next layer. Indicates next layer is ready to receive
  data_r_o : handshake to next layer. The data from this layer to the next layer
*/
module relu_layer #(

  parameter WORD_SIZE=16) (

  // top level control
  input logic clk_i,
  input logic reset_i,

  // handshake to prev layer
  output logic ready_o,
  input logic valid_i,
  input logic signed [WORD_SIZE-1:0] data_r_i,

  // handshake to next layer
  output logic valid_o,
  input logic ready_i,
  output logic signed [WORD_SIZE-1:0] data_r_o);





// relu_layer CONTROLLER

  logic en_lo;
  single_fifo_ctrl #() relu_ctrl (
    .clk_i,
    .reset_i,
    .en_o(en_lo),

    .ready_o,
    .valid_i,

    .valid_o,
    .ready_i);

  
  



// relu_layer DATAPATH
  
  // comparator
  always_ff @(posedge clk_i) begin
    if (en_lo)
	   data_r_o <= data_r_i[WORD_SIZE-1] ? '0 : data_r_i;
	else
	   data_r_o <= data_r_o;
  end

endmodule