`timescale 1ns / 1ps
`ifndef SYNOPSIS
`define VIVADO
`endif
/**
Alex Knowlton
4/12/2023

Inferred block RAM using Xylinx Vivado. Wraps Vivado macro in drop-in replacement for previous ROM.
*/

module ROM_inferred #(
   parameter ADDR_WIDTH=3,
   parameter WORD_SIZE=8,
   parameter MEM_INIT="0_1_0.mif",
   parameter LAYER_NUMBER=1
) (
   `ifndef VIVADO
   input logic [WORD_SIZE-1:0] data_i,
   input logic wen_i,
   `endif
   
   input logic [ADDR_WIDTH-1:0] addr_i,
   output logic [WORD_SIZE-1:0] data_o,
   input logic reset_i,
   input logic clk_i
);
   `ifdef VIVADO
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
   `else
   logic reset_null;
   assign reset_null = reset_i;

   generate
      if (WORD_SIZE == 21) begin
         // 21x256 for bn layer
         sram_21_256_freepdk45 ram (
            .clk0(clk_i),
            .csb0(1'b0),
            .web0(wen_i),
            .addr0(addr_i),
            .din0(data_i),
            .dout0(data_o)
         );
      end else begin
         if (ADDR_WIDTH == 6) begin
            // 16x64 RAM for convolution
            sram_16_64_freepdk45 ram (
               .clk0(clk_i),
               .csb0(1'b0),
               .web0(wen_i),
               .addr0(addr_i),
               .din0(data_i),
               .dout0(data_o)
            );
         end else if (ADDR_WIDTH == 8) begin
            // 16x256 RAM for hidden layer
            sram_16_256_freepdk45 ram (
               .clk0(clk_i),
               .csb0(1'b0),
               .web0(wen_i),
               .addr0(addr_i),
               .din0(data_i),
               .dout0(data_o)
            );
         end else begin
            // 16x512 RAM for output layer
            sram_16_512_freepdk45 ram (
               .clk0(clk_i),
               .csb0(1'b0),
               .web0(wen_i),
               .addr0(addr_i),
               .din0(data_i),
               .dout0(data_o)
            );
         end
      end
   endgenerate
   `endif

endmodule
