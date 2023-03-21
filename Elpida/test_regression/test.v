`timescale 1ns / 1ps

`include "test_regression/include.v"
`include "test_regression/Layer_1.v"

module test();
    reg clk;
    reg rst;
    reg [`dataWidth-1:0] in;
    reg in_valid;
    reg wvalid;
    reg bvalid;
    reg [`dataWidth:0] wdata;
    reg [`dataWidth:0] bdata;
    reg [`dataWidth:0] layer_num;
    reg [`dataWidth:0] neuron_num;
    wire [`numNeuronLayer1*`dataWidth-1:0] out;
    wire [`numNeuronLayer1-1:0] outvalid;

    // generate the clock
    initial begin
        clk = 1'b0;
        forever #1 clk=~clk;
    end

    // Generate the reset
    initial begin
        rst = 1'b1;
        #10
        rst = 1'b0;
    end

    // monitor 
    initial begin
        $monitor("time=%3d, in_valid=%b, wvalid=%b \n",$time, in_valid, wvalid);
        in_valid = 1'b0;
        wvalid = 1'b0;
        #20
        in_valid = 1'b1;
        #20
        wvalid = 1'b1;
    end

    Layer_1 #(.NN(`numNeuronLayer1),.numWeight(`numWeightLayer1),.dataWidth(`dataWidth),.layerNum(1),.sigmoidSize(10),.weightIntWidth(`weightIntWidth),.actType("regression")) L1
    (.clk(clk),
    .rst(rst),
    .weightValid(wvalid),
    .biasValid(bvalid),
    .weightValue(wdata),
    .biasValue(bdata),
    .config_layer_num(layer_num),
    .config_neuron_num(neuron_num),
    .x_valid(in_valid),
    .x_in(in),
    .o_valid(outvalid),
    .x_out(out)
    );

integer waves;

// write .csv file
initial begin 
    waves = $fopen("test_regression/output_files/waves.csv");
    forever #1 $fwrite(waves,"%d,%d,%d,%d\n", clk, rst, in_valid, wvalid);
end

// dump waveforms
initial begin 
    $dumpfile("test_regression/output_files/dump.vcd");
    $dumpvars(1);
    #240 $finish;
end

endmodule
