`include "test_regression/include.v"
`include "test_regression/neuron.v"

module Layer_1 #(parameter NN = 1,numWeight=5,dataWidth=16,layerNum=1,sigmoidSize=10,weightIntWidth=4,actType="regression")
    (
    input           clk,
    input           rst,
    input           weightValid,
    input           biasValid,
    input [`weightValWidth-1:0]    weightValue,
    input [`biasValWidth-1:0]    biasValue,
    input [31:0]    config_layer_num,
    input [31:0]    config_neuron_num,
    input           x_valid,
    input [dataWidth-1:0]    x_in,
    output [NN-1:0]     o_valid,
    output [NN*dataWidth-1:0]  x_out
    );
neuron #(.numWeight(numWeight),.layerNo(layerNum),.neuronNo(0),.dataWidth(dataWidth),.sigmoidSize(sigmoidSize),.weightIntWidth(weightIntWidth),.actType(actType),.weightFile("test_regression/weights/w_1_0.mif"),.biasFile("test_regression/biases/b_1_0.mif"))n_0(
        .clk(clk),
        .rst(rst),
        .myinput(x_in),
        .weightValid(weightValid),
        .biasValid(biasValid),
        .weightValue(weightValue),
        .biasValue(biasValue),
        .config_layer_num(config_layer_num),
        .config_neuron_num(config_neuron_num),
        .myinputValid(x_valid),
        .out(x_out[0*dataWidth+:dataWidth]),
        .outvalid(o_valid[0])
        );
endmodule