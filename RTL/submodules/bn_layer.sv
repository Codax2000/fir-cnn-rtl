/**
Eugene Liu
4/4/2023

Batch normalization layer. Sequentially applies normalization to inputs.

Interface: Uses a valid-ready handshakes. Is a helpful producer and consumer. The data_r_i is expected to come directly from a register, and data_r_o comes directly from a register.
Implementation: An internal counter tracks which mean/variance/scale/offset is applied to which data_r_i, and the counter automatically resets properly.

parameters:
  INPUT_SIZE        : number of inputs (the output size of the previous layer)
  WORD_SIZE         : the number of bits of inputs/outputs
  MEM_INIT_MEAN     : .mif file for the mean mem
  MEM_INIT_VARIANCE : .mif file for the variance mem
  MEM_INIT_SCALE    : .mif file for the scale mem
  MEM_INIT_OFFSET   : .mif file for the offset mem

input-outputs:
  clk_i    : input clock
  reset_i  : reset signal. Resets counter, controller, and data_r_o

  ready_o  : handshake to prev layer. Indicates this layer is ready to recieve
  valid_i  : handshake to prev layer. Indicates prev layer has valid data
  data_r_i : handshake to prev layer. The data from the prev layer to this layer

  valid_o  : handshake to next layer. Indicates this layer has valid data
  ready_i  : handshake to next layer. Indicates next layer is ready to receive
  data_r_o : handshake to next layer. The data from this layer to the next layer

*/

module bn_layer #(

  parameter INPUT_SIZE=1,
  parameter WORD_SIZE=16,
  parameter MEM_INIT_MEAN="mean_test.mif",
  parameter MEM_INIT_VARIANCE="variance_test.mif",
  parameter MEM_INIT_SCALE="scale_test.mif",
  parameter MEM_INIT_OFFSET="offset_test.mif") (

  // top level control
  input logic clk_i,
  input logic reset_i,

  // handshake to prev layer
  output logic ready_o,
  input logic valid_i,
  input signed logic [WORD_SIZE-1:0] data_r_i,

  // handshake to next layer
  output logic valid_o,
  input logic ready_i,
  output signed logic [WORD_SIZE-1:0] data_r_o);





// BN_LAYER CONTROLLER

  // controller states
  typedef enum logic {eEMPTY=0, eFULL=1} state_e;
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
    endcase
  end

  // controller signal logic
  logic en_li;
  assign en_li = ((state_r==eEMPTY) && valid_i) | (ready_i && valid_i);
  assign ready_o = (state_r==eEMPTY) | ready_i;
  assign valid_o = state_r == eFULL;





// BN_LAYER DATAPATH

  // up counter with enable
  logic [$clog2(INPUT_SIZE)-1:0] count_r,count_n;
  always_ff @(posedge clk_i)
    count_r <= count_n;

  always_comb begin
    if (reset_i)
      count_n = 0;
    else if (en_li) begin
      if (count_r==INPUT_SIZE-1)
        count_n = 0;
      else
        count_n = count_r+1;
    end else
      count_n = count_r;
  end

  // mean rom
  logic signed [$clog2(INPUT_SIZE)-1:0] mean_lo;
  ROM #(.depth($clog2(INPUT_SIZE)),
        .width(WORD_SIZE),
        .init_file(MEM_INIT_MEAN)) mean_mem (
    .clk_i,
    .addr_i(count_n),
    .data_r_o(mean_lo)
  );

  // variance rom
  logic signed [$clog2(INPUT_SIZE)-1:0] variance_lo;
  ROM #(.depth($clog2(INPUT_SIZE)),
        .width(WORD_SIZE),
        .init_file(MEM_INIT_VARIANCE)) variance_mem (
    .clk_i,
    .addr_i(count_n),
    .data_r_o(variance_lo)
  );

  // scale rom
  logic signed [$clog2(INPUT_SIZE)-1:0] scale_lo;
  ROM #(.depth($clog2(INPUT_SIZE)),
        .width(WORD_SIZE),
        .init_file(MEM_INIT_SCALE)) scale_mem (
    .clk_i,
    .addr_i(count_n),
    .data_r_o(scale_lo)
  );

  // offset rom
  logic signed [$clog2(INPUT_SIZE)-1:0] offset_lo;
  ROM #(.depth($clog2(INPUT_SIZE)),
        .width(WORD_SIZE),
        .init_file(MEM_INIT_OFFSET)) offset_mem (
    .clk_i,
    .addr_i(count_n),
    .data_r_o(offset_lo)
  );

  // forward computation logic
  always_ff @(posedge clk_i) begin
    if (en_li)
      data_r_o <= ((data_r_i - mean_lo) * variance_lo * scale_lo) + offset_lo;
    else
      data_r_o <= data_r_o;
  end

endmodule