`timescale 1ns / 1ps

`include "test_regression/include.v"
`include "test_regression/neuron.v"


module test();
    reg clk;
    reg rst;
    reg [`dataWidth-1:0] in;
    reg in_valid;
    reg wvalid;
    reg bvalid;
    reg [`dataWidth-1:0] wdata;
    reg [`dataWidth-1:0] bdata;
    reg [`dataWidth-1:0] layer_num;
    reg [`dataWidth-1:0] neuron_num;
    wire [`numNeuronLayer1*`dataWidth-1:0] out;
    wire [`numNeuronLayer1-1:0] outvalid;
    wire [2:0] r_addr;

    // generate the clock
    initial begin
        clk = 1'b0;
        forever #1 clk=~clk;
    end

    // Generate the reset
    initial begin
        rst = 1'b1;
        in_valid = 0;
        wvalid=0;
        #10
        rst = 1'b0;
        wvalid=1;
        in_valid=1;
        wdata = 16'b0000_1100_1100_1100;
        in = 16'b0000_1100_1100_1100;
        #2
        wdata = 16'b1110_0110_0110_0110;
        in = 16'b1110_0110_0110_0110;
        #2
        wdata = 16'b0010_0110_0110_0110;
        in = 16'b0010_0110_0110_0110;
        #2
        wdata = 16'b1100_1100_1100_1100;
        in = 16'b1100_1100_1100_1100;
        #2
        wdata = 16'b0100_0000_0000_0000;
        in = 16'b0100_0000_0000_0000;
    end

    neuron #(.numWeight(5),.weightIntWidth(1),.actType("regression"))N1(
        .clk(clk),
        .rst(rst),
        .myinput(in),
        .myinputValid(in_valid),
        .weightValid(wvalid),
        .biasValid(1'b1),
        .weightValue(wdata),
        .biasValue(16'b0000_1100_1100_1100),
        .config_layer_num(0),
        .config_neuron_num(0),
        .out(out),
        .outvalid(outvalid),
        .r_addr(r_addr)  // REMOVE
    );

    // dump waveforms
    initial begin 
        $dumpfile("test_regression/output_files/dump.vcd");
        $dumpvars(1);
        #240 $finish;
    end

endmodule
