`timescale 1ns / 1ps
/**
Alex Knowlton
4/12/2023

Inferred block RAM using Xylinx Vivado. Wraps Vivado macro in drop-in replacement for previous ROM.
*/

module ROM_inferred #(
   parameter ADDR_WIDTH=3,
   parameter WORD_SIZE=8,
   parameter MEM_INIT="0_1_0.mif"
) (
   input logic [ADDR_WIDTH-1:0] addr_i,
   output logic [WORD_SIZE-1:0] data_o,
   input logic clk_i,
   input logic reset_i
);

   xpm_memory_sprom #(
      .ADDR_WIDTH_A(ADDR_WIDTH),              // DECIMAL
      .MEMORY_INIT_FILE(MEM_INIT),     // String
      .MEMORY_OPTIMIZATION("true"),  // String
      .MEMORY_PRIMITIVE("block"),     // String
      .MEMORY_SIZE((2**ADDR_WIDTH)*WORD_SIZE),            // DECIMAL
      .MESSAGE_CONTROL(0),           // DECIMAL
      .READ_DATA_WIDTH_A(WORD_SIZE),        // DECIMAL
      .READ_LATENCY_A(1),            // DECIMAL
      .READ_RESET_VALUE_A("0"),      // String
      .RST_MODE_A("SYNC"),           // String
      .SIM_ASSERT_CHK(0),            // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_MEM_INIT(1),              // DECIMAL
      .USE_MEM_INIT_MMI(0),          // DECIMAL
      .WAKEUP_TIME("disable_sleep")  // String
   )
   xpm_memory_sprom_inst (
      .douta(data_o),                   // READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
      .addra(addr_i),                   // ADDR_WIDTH_A-bit input: Address for port A read operations.
      .clka(clk_i),                     // 1-bit input: Clock signal for port A.
      .ena(1'b1),                       // 1-bit input: Memory enable signal for port A. Must be high on clock
                                       // cycles when read operations are initiated. Pipelined internally.
      .rsta(reset_i),                     // 1-bit input: Reset signal for the final port A output register stage.
                                       // Synchronously resets output port douta to the value specified by
                                       // parameter READ_RESET_VALUE_A.
      .injectsbiterra(1'b0),
      .injectdbiterra(1'b0),
      .regcea(1'b1),
      .sleep(1'b0)
);

endmodule