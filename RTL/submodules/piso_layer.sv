`timescale 1ns / 1ps
/**
Eugene Liu
5/11/2023

Parallel-In-Serial-Out layer module. Consumes a variable number of words in parallel and sequentially outputs those words.

Interface: Uses valid-ready handshakes. Is a helpful producer and consumer.
Implementation: An internal register file with a counter that sweeps its read address from 0 to data_size_i-1. data_size_i is 
    registered with a successful handshake to the prev layer. The counter automatically resets to 0 after the last word is produced.

Parameters:
    MAX_INPUT_SIZE : number of maximum input words (dictates sizing of input data_i port)
    WORD_SIZE      : number of bits in a word

Inputs-Outputs:
    clk_i       : clock signal
    reset_i     : reset signal

    ready_o     : handshake to prev layer. Indicates this layer is ready to recieve
    valid_i     : handshake to prev layer. Indicates prev layer has valid data
    data_i      : handshake to prev layer. The parallel data from the prev layer to this layer
    data_size_i : handshake to prev layer. The number of valid words from the prev layer to this layer
    
    valid_o     : handshake to next layer. Indicates this layer has valid data
    ready_i     : handshake to next layer. Indicates next layer is ready to receive
    data_o      : handshake to next layer. The data from this layer to the next layer
*/

module piso_layer #(

    parameter MAX_INPUT_SIZE=5,
    parameter WORD_SIZE=16) (
    
    // top-level control
    input logic clk_i,
    input logic reset_i,
    
    // helpful handshake to prev layer
    input logic valid_i,
    output logic ready_o,
    input logic signed [MAX_INPUT_SIZE-1:0][WORD_SIZE-1:0] data_i,
    input logic [$clog2(MAX_INPUT_SIZE)-1:0] data_size_i,

    // helpful handshake to next layer
    output logic valid_o,
    input logic ready_i,
    output logic [WORD_SIZE-1:0] data_o
    );
    
    
    
    
// CONTROLLER
    
    // controller states
    typedef enum logic {eREADY=1'b1, eVALID=1'b0} state_e;
    state_e state_n, state_r;
    
    // state register
    always_ff @(posedge clk_i) begin
        if (reset_i)
            state_r <= eREADY;
        else
            state_r <= state_n;
    end
    
    // next state logic
    logic is_final_word;
    always_comb begin
        case (state_r)
            eREADY: state_n = valid_i ? eVALID : eREADY;
            eVALID: state_n = (ready_i && is_final_word) ? eREADY : eVALID;
            default: state_n = eREADY;
        endcase
    end
    
    // output logic
    assign ready_o = (state_r == eREADY);
    assign valid_o = (state_r == eVALID);
    
    // control logic
    logic consume_en, produce_en;
    assign consume_en = ready_o && valid_i; // indicates this layer is to consume from prev layer
    assign produce_en = valid_o && ready_i; // indicates this layer is to produce to next layer
    
    
    
    
    
// DATAPATH
    
    // input registers
    logic [$clog2(MAX_INPUT_SIZE)-1:0] data_size_r;
    always_ff @(posedge clk_i) begin
        if (reset_i)
            data_size_r = MAX_INPUT_SIZE;
        else
            data_size_r = consume_en ? data_size_i : data_size_r;
    end
    
    // upcounter
    logic [$clog2(MAX_INPUT_SIZE)-1:0] count_r, count_n;
    always_ff @(posedge clk_i) begin
        count_r = count_n;
    end
    
    always_comb begin
        is_final_word = (count_r == data_size_r-1);
    
        if (reset_i)
            count_n = '0;
        else if (produce_en)
            count_n = is_final_word ? '0 : count_r+1;
        else
            count_n = count_r;
    end
    
    // register file
    logic [MAX_INPUT_SIZE-1:0][WORD_SIZE-1:0] data_r;
    always_ff @(posedge clk_i) begin
        data_r = consume_en ? data_i : data_r;
    end

    // output logic
    assign data_o = data_r[count_r];


endmodule