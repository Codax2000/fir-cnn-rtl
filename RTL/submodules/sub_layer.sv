`timescale 1ns / 1ps

/**
Eugene Liu
4/17/2023

Subtraction layer. Sequentially subtracts two inputs from each other

Interface: Uses valid-ready handshakes. Is a demanding consumer and a helpful producer. The data_r_i is expected to come directly from a register, and data_r_o comes directly from a register.
Implementation: Performs data_r_o <= data1_r_i - data2_r_i

parameters:
  WORD_SIZE : the number of bits of inputs/outputs

input-outputs:
  clk_i    : input clock
  reset_i  : reset signal. Resets controller
  en_o     : enable signal used by datapath to consume data

  ready_o  : handshake to prev layers. Indicates this layer is ready to recieve
  valid_i  : handshake to prev layers. Indicates prev layers have valid data

  valid_o  : handshake to next layer. Indicates this layer has valid data
  ready_i  : handshake to next layer. Indicates next layer is ready to receive
*/
module sub_layer #(

  parameter WORD_SIZE=16) (

  // top level control
  input logic clk_i,
  input logic reset_i,

  // handshake to prev layer
  output logic ready_o,
  input logic [1:0] valid_i,
  input logic signed [WORD_SIZE-1:0] data1_r_i, data2_r_i,

  // handshake to next layer
  output logic valid_o,
  input logic ready_i,
  output logic signed [WORD_SIZE-1:0] data_r_o);





// sub_layer CONTROLLER

  logic en_lo;
  multi_input_layer_ctrl #(.NUM_INPUTS(2)) sub_ctrl (
    .clk_i,
    .reset_i,
    .en_o(en_lo),

    .ready_o,
    .valid_i,

    .valid_o,
    .ready_i);
  
  
  
  
  
// sub_layer DATAPATH
  
  // forward computation logic
  logic signed [WORD_SIZE-1:0] data_n_o;
  always_ff @(posedge clk_i) begin
    if (en_lo)
	   data_r_o <= data_n_o;
	else
	   data_r_o <= data_r_o;
  end
  
  // subtractor
  safe_alu #(.WORD_SIZE(WORD_SIZE),.OPERATION("sub")) sub1 (
    .a_i(data1_r_i),
    .b_i(data2_r_i),
    .data_o(data_n_o)
  );

endmodule