`timescale 1ns / 1ps

/**
Eugene Liu
4/10/2023

Controller for a single element FIFO. Useful for controlling some layers

Interface: Uses a valid-ready handshakes. Is a helpful producer and consumer. The data_r_i is expected to come directly from a register, and data_r_o comes directly from a register.
Implementation: FSM

parameters: N/A

input-outputs:
  clk_i    : input clock
  reset_i  : reset signal. Resets counter, controller, and data_r_o

  ready_o  : handshake to prev layer. Indicates this layer is ready to recieve
  valid_i  : handshake to prev layer. Indicates prev layer has valid data

  valid_o  : handshake to next layer. Indicates this layer has valid data
  ready_i  : handshake to next layer. Indicates next layer is ready to receive
*/
module single_fifo_ctrl #() (

  // top level control
  input logic clk_i,
  input logic reset_i,
  output logic en_o,

  // handshake to prev layer
  output logic ready_o,
  input logic valid_i,

  // handshake to next layer
  output logic valid_o,
  input logic ready_i);





// SINGLE_FIFO CONTROLLER

  // controller states
  typedef enum logic {eEMPTY=1'b0, eFULL=1'b1} state_e;
  state_e state_n, state_r;

  // state register
  always_ff @(posedge clk_i) begin
    if (reset_i)
      state_r <= eEMPTY;
    else
      state_r <= state_n;
  end

  // next state logic
  always_comb begin
    case (state_r)
      eEMPTY: state_n = valid_i ? eFULL : eEMPTY;
      eFULL: state_n = (ready_i && !valid_i) ? eEMPTY : eFULL;
      default: state_n = eEMPTY;
    endcase
  end

  // controller signal logic
  assign en_o = ((state_r==eEMPTY) && valid_i) | (ready_i && valid_i);
  assign ready_o = (state_r==eEMPTY) | ready_i;
  assign valid_o = state_r == eFULL;

endmodule