`timescale 1ns / 1ps

/**
Eugene Liu
4/4/2023

Batch normalization layer. Sequentially applies normalization to inputs.

Interface: Uses a valid-ready handshakes. Is a helpful producer and consumer. The data_r_i is expected to come directly from a register, and data_r_o comes directly from a register.
Implementation: An internal counter tracks which mean/variance/scale/offset is applied to which data_r_i, and the counter automatically resets properly.

parameters:
  INPUT_SIZE   : number of inputs (the output size of the previous layer)
  LAYER_NUMBER : the layer number (for automatic .mem file naming)
  WORD_SIZE    : the number of bits of inputs/outputs
  N_SIZE       : the n parameter for Qm.n fixed point notation

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

module bn_layer #(

  parameter INPUT_SIZE=1,
  parameter LAYER_NUMBER=1,
  parameter WORD_SIZE=16,
  parameter N_SIZE=14) (

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





// BN_LAYER CONTROLLER

  logic en_lo;
  single_fifo_ctrl #() bn_ctrl (
    .clk_i,
    .reset_i,
    .en_o(en_lo),

    .ready_o,
    .valid_i,

    .valid_o,
    .ready_i);





// BN_LAYER DATAPATH

  // up counter with enable
  logic [$clog2(INPUT_SIZE)-1:0] count_r,count_n;
  always_ff @(posedge clk_i)
    count_r <= count_n;

  always_comb begin
    if (reset_i)
      count_n = 0;
    else if (en_lo) begin
      if (count_r==INPUT_SIZE-1)
        count_n = 0;
      else
        count_n = count_r+1;
    end else
      count_n = count_r;
  end

  // mean rom
  logic signed [WORD_SIZE-1:0] mean_lo;
  ROM_neuron #(
    .depth($clog2(INPUT_SIZE)),
    .width(WORD_SIZE),
    .neuron_type(2),
    .layer_number(LAYER_NUMBER),
    .neuron_number(0)
  ) mean_mem (
    .reset_i,
    .clk_i,
    .addr_i(count_n),
    .data_o(mean_lo)
  );

  // variance rom
  logic signed [WORD_SIZE-1:0] variance_lo;
  ROM_neuron #(
    .depth($clog2(INPUT_SIZE)),
    .width(WORD_SIZE),
    .neuron_type(2),
    .layer_number(LAYER_NUMBER),
    .neuron_number(1)
  ) variance_mem (
    .reset_i,
    .clk_i,
    .addr_i(count_n),
    .data_o(variance_lo)
  );

  // scale rom
  logic signed [WORD_SIZE-1:0] scale_lo;
  ROM_neuron #(
    .depth($clog2(INPUT_SIZE)),
    .width(WORD_SIZE),
    .neuron_type(2),
    .layer_number(LAYER_NUMBER),
    .neuron_number(2)
  ) scale_mem (
    .reset_i,
    .clk_i,
    .addr_i(count_n),
    .data_o(scale_lo)
  );

  // offset rom
  logic signed [WORD_SIZE-1:0] offset_lo;
  ROM_neuron #(
    .depth($clog2(INPUT_SIZE)),
    .width(WORD_SIZE),
    .neuron_type(2),
    .layer_number(LAYER_NUMBER),
    .neuron_number(3)
  ) offset_mem (
    .reset_i,
    .clk_i,
    .addr_i(count_n),
    .data_o(offset_lo)
  );

  // forward computation logic
  logic signed [WORD_SIZE-1:0] data_n_o, data1, data2, data3;
  always_ff @(posedge clk_i) begin
    if (en_lo)
      data_r_o <= data_n_o;
    else
      data_r_o <= data_r_o;
  end
  
  safe_alu #(.WORD_SIZE(WORD_SIZE),.N_SIZE(N_SIZE),.OPERATION("sub")) sub1 (
    .a_i(data_r_i),
    .b_i(mean_lo),
    .data_o(data1)
  );
  
  safe_alu #(.WORD_SIZE(WORD_SIZE),.N_SIZE(N_SIZE),.OPERATION("mult")) mult1 (
    .a_i(data1),
    .b_i(variance_lo),
    .data_o(data2)
  );
  
  safe_alu #(.WORD_SIZE(WORD_SIZE),.N_SIZE(N_SIZE),.OPERATION("mult")) mult2 (
    .a_i(data2),
    .b_i(scale_lo),
    .data_o(data3)
  );
  
  safe_alu #(.WORD_SIZE(WORD_SIZE),.N_SIZE(N_SIZE),.OPERATION("add")) add1 (
    .a_i(data3),
    .b_i(offset_lo),
    .data_o(data_n_o)
  );
  
<<<<<<< Updated upstream
=======
  // output truncation logic
  always_comb begin
    data_n_o = data4[WORD_SIZE-1:0];
  
    if (data4[MEM_WORD_SIZE-1] && !(&data4[MEM_WORD_SIZE-2:WORD_SIZE-1]))
      data_n_o = {1'b1,{(WORD_SIZE-1){1'b0}}}; // underflow
    if (!data4[MEM_WORD_SIZE-1] && |data4[MEM_WORD_SIZE-2:WORD_SIZE-1])
      data_n_o = {1'b0,{(WORD_SIZE-1){1'b1}}}; // overflow
  end
  
>>>>>>> Stashed changes
endmodule