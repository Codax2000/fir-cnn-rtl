/**
Eugene Liu
4/4/2023

Batch normalization layer. Normalizes inputs.
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
  input signed logic [WORD_SIZE-1:0] data_i,

  // handshake to next layer
  output logic valid_o,
  input logic ready_i,
  output signed logic [WORD_SIZE-1:0] data_o);





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
  logic [$clog2(INPUT_SIZE)-1:0] count_r;
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
    .data_o(mean_lo)
  );

  // variance rom
  logic signed [$clog2(INPUT_SIZE)-1:0] variance_lo;
  ROM #(.depth($clog2(INPUT_SIZE)),
        .width(WORD_SIZE),
        .init_file(MEM_INIT_VARIANCE)) variance_mem (
    .clk_i,
    .addr_i(count_n),
    .data_o(variance_lo)
  );

  // scale rom
  logic signed [$clog2(INPUT_SIZE)-1:0] scale_lo;
  ROM #(.depth($clog2(INPUT_SIZE)),
        .width(WORD_SIZE),
        .init_file(MEM_INIT_SCALE)) scale_mem (
    .clk_i,
    .addr_i(count_n),
    .data_o(scale_lo)
  );

  // offset rom
  logic signed [$clog2(INPUT_SIZE)-1:0] offset_lo;
  ROM #(.depth($clog2(INPUT_SIZE)),
        .width(WORD_SIZE),
        .init_file(MEM_INIT_OFFSET)) offset_mem (
    .clk_i,
    .addr_i(count_n),
    .data_o(offset_lo)
  );

  // forward computation logic
  always_ff @(posedge clk_i) begin
    if (en_li)
      data_o <= ((data_i - mean_lo) * variance_lo * scale_lo) + offset_lo;
    else
      data_o <= data_o;
  end

endmodule