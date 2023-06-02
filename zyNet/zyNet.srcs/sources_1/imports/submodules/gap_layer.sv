`timescale 1ns / 1ps

/**
Eugene Liu
4/10/2023

Global averaging pooling layer. Computes an average with sequential inputs.

Interface: Uses a valid-ready handshakes. Is a helpful producer and consumer. The data_r_i is expected to come directly from a register, and data_r_o comes directly from a register.
Implementation: An internal counter tracks the input number, and is used to initialize value and exit computation loop. The counter automatically resets properly.

Parameters:
  INPUT_SIZE   : per-channel input tensor size
  WORD_SIZE    : the number of bits of inputs/outputs
  N_SIZE       : the n parameter for Qm.n fixed point notation
  NUM_CHANNELS : the number of input channels
  
Derived Parameters
  MULTIPLIER : a multiplier representing 1/INPUT_SIZE. Default value is auto-computed in Qm.n format.

input-outputs:
  clk_i    : input clock
  reset_i  : reset signal. Resets counter, controller. data_r_o remains the same.

  ready_o  : handshake to prev layer. Indicates this layer is ready to recieve
  valid_i  : handshake to prev layer. Indicates prev layer has valid data
  data_r_i : handshake to prev layer. The data from the prev layer to this layer

  valid_o  : handshake to next layer. Indicates this layer has valid data
  ready_i  : handshake to next layer. Indicates next layer is ready to receive
  data_r_o : handshake to next layer. The data from this layer to the next layer
*/

module gap_layer #(

  parameter INPUT_SIZE=1,
  parameter WORD_SIZE=16,
  parameter N_SIZE=12,
  parameter NUM_CHANNELS=1,
  
  // derived parameter
  parameter signed [WORD_SIZE-1:0] MULTIPLIER=$rtoi((2.0**N_SIZE)/$itor(INPUT_SIZE))) (

  // top level control
  input logic clk_i,
  input logic reset_i,

  // handshake to prev layer
  output logic ready_o,
  input logic valid_i,
  input logic signed [NUM_CHANNELS*WORD_SIZE-1:0] data_r_i,

  // handshake to next layer
  output logic valid_o,
  input logic ready_i,
  output logic signed [NUM_CHANNELS*WORD_SIZE-1:0] data_r_o);





// GAP_LAYER CONTROLLER

  // controller states
  typedef enum logic {eBUSY=1'b0, eDONE=1'b1} state_e;
  state_e state_n, state_r;

  // state register
  always_ff @(posedge clk_i) begin
    if (reset_i)
      state_r <= eBUSY;
    else
      state_r <= state_n;
  end

  // next state logic
  logic [$clog2(INPUT_SIZE)-1:0] count_r;
  always_comb begin
    case (state_r)
      eBUSY: state_n = (valid_i && (count_r == INPUT_SIZE-1)) ? eDONE : eBUSY;
      eDONE: state_n = !ready_i ? eDONE : eBUSY;
      default: state_n = eBUSY;
    endcase
  end

  // controller signal logic
  logic en_lo;
  assign en_lo = ((state_r == eBUSY) && valid_i) | (ready_i && valid_i);
  assign ready_o = (state_r == eBUSY) | ready_i;
  assign valid_o = state_r == eDONE;





// GAP_LAYER DATAPATH

  // up counter with enable and auto-reset before overflow
  logic [$clog2(INPUT_SIZE)-1:0] count_n;
  always_ff @(posedge clk_i)
    count_r <= count_n;

  always_comb begin
    if (reset_i)
      count_n = 0;
    else if (en_lo) begin
      if (count_r == INPUT_SIZE-1)
        count_n = 0;
      else
        count_n = count_r+1;
    end else
      count_n = count_r;
  end

  // accumulators
  genvar i;
  generate
      for (i=0; i<NUM_CHANNELS; i=i+1) begin
          // accumulator register
          logic signed [2*WORD_SIZE-1:0] sum_r, sum_n, data_mult;
          always_ff @(posedge clk_i) begin
            if (en_lo)
              sum_r <= (count_r == 0) ? data_mult : sum_n;
            else
              sum_r <= sum_r;
          end
          
          // accumulation combinational logic
          assign data_mult = data_r_i[(i+1)*WORD_SIZE-1:i*WORD_SIZE]*MULTIPLIER;
          
          safe_alu #(.WORD_SIZE(2*WORD_SIZE),.N_SIZE(2*N_SIZE),.OPERATION("add")) add1 (
            .a_i(data_mult),
            .b_i(sum_r),
            .data_o(sum_n)
          );
          
          // output logic
          safe_alu #(.WORD_SIZE(WORD_SIZE),.N_SIZE(N_SIZE),.OPERATION("trunc")) trunc1 (
            .a_i(sum_r),
            .b_i(),
            .data_o(data_r_o[(i+1)*WORD_SIZE-1:i*WORD_SIZE])
          );
      end
  endgenerate

endmodule