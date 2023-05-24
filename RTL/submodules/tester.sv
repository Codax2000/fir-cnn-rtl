`timescale 1ns / 1ps

/**
Eugene Liu
5/23/2023

Synthesizable module for testing another module given inputs as a .mif file

Interface: Uses a valid-ready handshakes. Is a helpful producer and consumer. The data_r_i is expected to come directly from a register, and data_r_o comes directly from a register.
Implementation: A counter sweeps through all 

Parameters:
    WORD_SIZE       : the bit width of words
    NUM_WORDS       : the number of words per mem address
    NUM_TESTS       : the number of tests or mem addresses
    TEST_INPUT_FILE : the name of the test data .mif file

Input-outputs:
    clk_i   : input clock
    reset_i : reset signal. Resets counter, controller, and data_r_o
    start_i : start signal to start testing all test cases
    
    ready_o : handshake to the output of the dut. Indicates this module is ready to recieve
    yumi_i  : handshake to the output of the dut. Indicates the dut has valid data
    data_i  : the input data coming from the output of the dut
    
    valid_o : handshake to the input of the dut. Indicates this module has valid data
    ready_i : handshake to the input of the dut. Indicates the dut is ready to receive
    data_o  : the output data sent to the input of the dut
*/
module tester #(
    
    parameter WORD_SIZE=16,
    parameter NUM_WORDS=1,
    parameter NUM_TESTS=1,
    parameter TEST_INPUT_FILE="asd.mif") (
    
    // top level control
    input logic clk_i,
    input logic reset_i,
    output logic start_i,
    
    // helpful input handshake
    output logic ready_o,
    input logic valid_i,
    input logic signed [NUM_WORDS*WORD_SIZE-1:0] data_i,
    
    // helpful output handshake
    output logic valid_o,
    input logic yumi_i,
    output logic signed [NUM_WORDS*WORD_SIZE-1:0] data_o);
    
    
    
    
    
// SINGLE_FIFO CONTROLLER

    // controller states
    typedef enum logic [1:0] {eSTART=2'b00, eSEND=2'b01, eRECEIVE=2'b10} state_e;
    state_e state_n, state_r;
    
    // state register
    always_ff @(posedge clk_i) begin
        if (reset_i)
           state_r <= eSTART;
        else
           state_r <= state_n;
    end
    
    // next state logic
    logic [$clog2(NUM_TESTS)-1:0] test_count_r;
    logic is_last_test;
    always_comb begin
        case (state_r)
            eSTART: state_n = start_i ? eSEND : eSTART;
            eSEND: state_n = yumi_i ? eRECEIVE : eSEND;
            eRECEIVE: begin
                if (valid_i)
                    state_n = is_last_test ? eSTART : eSEND;
                else
                    state_n = eRECEIVE;
                end
            default: state_n = eSTART;
        endcase
    end
    
    // controller signal logic
    assign ready_o = state_r == eRECEIVE;
    assign valid_o = state_r == eSEND;
    assign count_en = ready_o && valid_i;
    
    
    
    
    
// DATAPATH
    
    // upcounter tracks the number of tests completed
    logic [$clog2(NUM_TESTS)-1:0] test_count_n;
    always_ff @(posedge clk_i)
        test_count_r <= test_count_n;
    
    always_comb begin
        is_last_test = test_count_r == NUM_TESTS-1;
        
        if (reset_i)
            test_count_n = 0;
        else if (count_en)
            test_count_n = is_last_test ? 0 : test_count_n+1;
        else
            test_count_n = test_count_r;
    end
    
    // test data ROM
    logic [NUM_WORDS*WORD_SIZE-1:0] input_mem [NUM_TESTS-1:0];
    initial $readmemh(TEST_INPUT_FILE, input_mem);
    
    always_ff @(posedge clk_i)
        data_o = input_mem[test_count_n];
    
endmodule
