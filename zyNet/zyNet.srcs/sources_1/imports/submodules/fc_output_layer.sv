`timescale 1ns / 1ps
/**
Alex Knowlton
4/4/2023

Output for fully-connected layer. Performs parallel-to-serial shifting. For implementation using
a mux, use piso layer

parameters:
    LAYER HEIGHT:   number of words the layer should serialize
    WORD_SIZE   :   size of a word in bits

sync signals:
    clk_i   : input clock
    reset_i : input reset
    
helpful input handshake:
    valid_i : signal that incoming data is valid
    ready_o : signal that layer is ready to receive incoming data
    data_i  : WORD_SIZE*LAYER_HEIGHT bits. incoming data.
    
helpful output handshake:
    valid_o : signal that outgoing data is valid
    yumi_i  : signal that outgoing data has been consumed
    data_o  : WORD_SIZE bits. outgoing data.
*/

module fc_output_layer #(
    parameter LAYER_HEIGHT=5,
    parameter WORD_SIZE=16 ) (
    input logic clk_i,
    input logic reset_i,
    
    // helpful handshake to prev layer
    input logic valid_i,
    output logic ready_o,
    input logic [LAYER_HEIGHT-1:0][WORD_SIZE-1:0] data_i,

    // helpful handshake to next layer
    output logic valid_o,
    input logic yumi_i,
    output logic [WORD_SIZE-1:0] data_o
    );

    logic [$clog2(LAYER_HEIGHT+1)-1:0] count_shift_r, count_shift_n;
    enum logic {eREADY=1'b1, eSHIFT=1'b0} ps_e, ns_e;
    
    logic [LAYER_HEIGHT-1:0][WORD_SIZE-1:0] data_r, data_n;
    
    //// CONTROL LOGIC FSM
    always_comb begin
        case (ps_e)
            eREADY:
                if (valid_i)
                    ns_e = eSHIFT;
                else
                    ns_e = eREADY;
            eSHIFT:
                if ((count_shift_r == LAYER_HEIGHT - 1) && yumi_i)
                    ns_e = eREADY;
                else
                    ns_e = eSHIFT;
        endcase
    end
    
    always_ff @(posedge clk_i) begin
        if (reset_i)
            ps_e <= eREADY;
        else
            ps_e <= ns_e;
    end
    
    //// END CONTROL LOGIC ////
    
    //// BEGIN SUBSIDIARY CONTROL LOGIC ////
    assign valid_o = ps_e == eSHIFT;
    assign ready_o = ps_e == eREADY;
    
    // shift counter
    always_comb begin
        if ((count_shift_r == LAYER_HEIGHT) && yumi_i)
            count_shift_n = '0;
        else if (yumi_i)
            count_shift_n = count_shift_r + 1;
        else
            count_shift_n = count_shift_r;
    end
    
    always_ff @(posedge clk_i) begin
        if (reset_i || ps_e == eREADY)
            count_shift_r <= '0;
        else
            count_shift_r <= count_shift_n;
    end
    
    //// DATAPATH ////
    logic shift;
    assign shift = ps_e == eSHIFT && yumi_i;
    always_comb begin
        case (ps_e)
            eSHIFT:
                if (yumi_i)
                    data_n = data_r >> WORD_SIZE;
                else
                    data_n = data_r;
            eREADY:
                if (valid_i)
                    data_n = data_i;
                else
                    data_n = '0;
        endcase
    end
    
    always_ff @(posedge clk_i) begin
        if (reset_i)
            data_r <= '0;
        else
            data_r <= data_n;
    end
    
    assign data_o = data_r[0];
    
endmodule