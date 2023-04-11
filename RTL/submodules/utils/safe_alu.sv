`timescale 1ns / 1ps

/**
Eugene Liu
4/8/2023

A package with overflow and underflow safe adders, subtractors, and multipliers.

Interface: Fully combinational. Up to user to register data
Implementation:
  adder      : data_o = a_i + b_i
  subtractor : data_o = a_i - b_i
  multiplier : data_o = a_i * b_i multiplication result is truncated to WORD_SIZE

parameters:
  WORD_SIZE : the number of bits of inputs/outputs
  N_SIZE    : the n parameter for Qm.n fixed point notation
  M_SIZE    : the m parameter for Qm.n fixed point notation (not including sign bit)
  OPERATION : the desired operation expressed as a string (choose "add", "sub", or "mult")

input-outputs:
  a_i    : input operand a
  b_i    : input operand b
  data_o : output data
*/
module safe_alu #(

  parameter WORD_SIZE=16,
  parameter N_SIZE=14,
  parameter M_SIZE=WORD_SIZE-N_SIZE-1,
  parameter OPERATION="add") (
  
  input logic signed [WORD_SIZE-1:0] a_i, b_i,
  output logic signed [WORD_SIZE-1:0] data_o);
  
  
  
  
  
// DATAPATH
  generate
    case (OPERATION)
      
      // adder
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
      
      
      // subtractor
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
      
      
      // multiplier
      "mult": begin
        logic signed [2*WORD_SIZE-1:0] data_n_o;
        localparam MSB = 2*WORD_SIZE-1;
        
        always_comb begin
          data_n_o = a_i * b_i;
          data_o = data_n_o[MSB-(M_SIZE+1):N_SIZE];
          
          if (data_n_o[MSB] && !(&data_n_o[MSB-1:MSB-(M_SIZE+1)]))
            data_o = {1'b1,{(WORD_SIZE-1){1'b0}}}; // underflow
          if (!data_n_o[MSB] && |data_n_o[MSB-1:MSB-(M_SIZE+1)])
            data_o = {1'b0,{(WORD_SIZE-1){1'b1}}}; // overflow
        end
      end
      
    endcase
  endgenerate

endmodule