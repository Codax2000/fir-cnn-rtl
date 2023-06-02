`timescale 1ns / 1ps

/**
Eugene Liu
4/8/2023

A package with overflow and underflow safe adders, subtractors, multipliers, and complimentors.

Interface: Fully combinational. Up to user to register data
Implementation:
  add        : data_o = a_i + b_i    Result is truncated to WORD_SIZE. Overflows/underflows saturate.
  subtract   : data_o = a_i - b_i    Result is truncated to WORD_SIZE. Overflows/underflows saturate.
  multiply   : data_o = a_i * b_i    Result is truncated to WORD_SIZE. Overflows/underflows saturate.
  compliment : data_o = -a_i         Deals with edge case where a_i = most negative int, e.g. 3'b100
  truncate   : data_o = a_i[MSB-m:n] Truncates input of Q(2m).(2n) to an output of Qm.n. Overflows/underflows saturate.

parameters:
  WORD_SIZE : the number of bits of inputs/outputs
  N_SIZE    : the n parameter for Qm.n fixed point notation
  M_SIZE    : the m parameter for Qm.n fixed point notation (not including sign bit)
  OPERATION : the desired operation expressed as a string (choose "add", "sub", "mult", "comp", or "trunc")

input-outputs:
  a_i    : input operand a
  b_i    : input operand b
  data_o : output data
*/
module safe_alu #(

  parameter WORD_SIZE=16,
  parameter N_SIZE=14,
  parameter M_SIZE=WORD_SIZE-N_SIZE,
  parameter OPERATION="add") (
  
  input logic signed [((OPERATION=="trunc")+1)*WORD_SIZE-1:0] a_i, b_i,
  output logic signed [WORD_SIZE-1:0] data_o);
  
  
  
  
  
// DATAPATH
  generate
    case (OPERATION)
      
      
      // add
      "add": begin
        logic signed [WORD_SIZE:0] data_n_o;
        
        always_comb begin
          data_n_o = a_i + b_i;
          
          case (data_n_o[WORD_SIZE-:2])
            2'b10: data_o = {1'b1,{(WORD_SIZE-1){1'b0}}}; // underflow
            2'b01: data_o = {1'b0,{(WORD_SIZE-1){1'b1}}}; // overflow
            default: data_o = data_n_o[WORD_SIZE-1:0];
          endcase
        end
      end
      
      
      // subtract
      "sub": begin
        logic signed [WORD_SIZE:0] data_n_o;
        
        always_comb begin
          data_n_o = a_i - b_i;
          
          case (data_n_o[WORD_SIZE-:2])
            2'b10: data_o = {1'b1,{(WORD_SIZE-1){1'b0}}}; // underflow
            2'b01: data_o = {1'b0,{(WORD_SIZE-1){1'b1}}}; // overflow
            default: data_o = data_n_o[WORD_SIZE-1:0];
          endcase
        end
      end
      
      
      // multiply
      "mult": begin
        logic signed [2*WORD_SIZE-1:0] data_n_o;
        localparam MSB = 2*WORD_SIZE-1;
        
        always_comb begin
          data_n_o = a_i * b_i;
          data_o = data_n_o[MSB-M_SIZE:N_SIZE];
          
          if (data_n_o[MSB] && !(&data_n_o[MSB-1:MSB-M_SIZE]))
            data_o = {1'b1,{(WORD_SIZE-1){1'b0}}}; // underflow
          if (!data_n_o[MSB] && |data_n_o[MSB-1:MSB-M_SIZE])
            data_o = {1'b0,{(WORD_SIZE-1){1'b1}}}; // overflow
        end
      end
      
      
      // compliment
      "comp": begin
        always_comb begin          
          if (a_i == {1'b1,{(WORD_SIZE-1){1'b0}}})
            data_o = {1'b0,{(WORD_SIZE-1){1'b1}}}; // overflow
          else
            data_o = ~a_i + 1'b1;
        end
      end
      
      
      // truncate
      "trunc": begin
        localparam MSB = 2*WORD_SIZE-1;

        always_comb begin
          data_o = a_i[MSB-M_SIZE:N_SIZE];
          
          if (a_i[MSB] && !(&a_i[MSB-1:MSB-M_SIZE]))
            data_o = {1'b1,{(WORD_SIZE-1){1'b0}}}; // underflow
          if (!a_i[MSB] && |a_i[MSB-1:MSB-M_SIZE])
            data_o = {1'b0,{(WORD_SIZE-1){1'b1}}}; // overflow
        end
      end
      
      
    endcase
  endgenerate

endmodule