`timescale 1ns / 1ps

`include "test_regression/include.v"
`include "test_regression/Weight_memory.v"
`include "test_regression/relu.v"
`include "test_regression/regression.v"

// q2dec('myinputd',0,15,"bin") -> 16'b with 1 bit int
// q2dec('mul',1,30,"bin")      -> {16'b with 1 bit int} * {16'b with 1 bit int} = 32'b with 2 bit int
// q2dec('sum',1,30,"bin")      -> sum has the same form as mul (they are added together). 32'b with 2 bit int
// q2dec('comboAdd',0,31,"bin") -> {32'b with 2 bit int} + {32'b with 2 bit int} = 32'b with 2 bit int
// q2dec('bias',1,30,"bin")     -> bias needs to have the same form as sum (they are added together). 32'b with 2 bit int
// q2dec('out',0,15,"bin") -> 16'b with 1 bit int (output is trimmed)

module neuron #(parameter layerNo=0,neuronNo=0,numWeight=5,dataWidth=16,sigmoidSize=10,weightIntWidth=4,actType="relu",biasFile="test_regression/biases/b_1_0.mif",weightFile="test_regression/weights/w_1_0.mif")(
    input           clk,
    input           rst,
    input [dataWidth-1:0]    myinput,
    input           myinputValid,
    input           weightValid,
    input           biasValid,
    input [`weightValWidth-1:0]    weightValue,
    input [`biasValWidth-1:0]    biasValue,
    input [31:0]    config_layer_num,
    input [31:0]    config_neuron_num,
    output[dataWidth-1:0]    out,
    output reg      outvalid
    );
    
    parameter addressWidth = $clog2(numWeight);
    
    reg         wen;
    wire        ren;
    reg [addressWidth-1:0] w_addr;
    reg [addressWidth-1:0] r_addr;//read address has to reach until numWeight hence width is 1 bit more
    reg [dataWidth-1:0]  w_in;
    wire [dataWidth-1:0] w_out;
    reg [2*dataWidth-1:0]  mul; 
    reg [2*dataWidth-1:0]  sum;
    reg [2*dataWidth-1:0]  bias;
    reg [`biasValWidth:0]    biasReg[`numNeuronLayer1-1:0];
    reg         weight_valid;
    reg         mult_valid;
    wire        mux_valid;
    reg         sigValid; 
    wire [2*dataWidth:0] comboAdd;
    wire [2*dataWidth:0] BiasAdd;
    reg  [dataWidth-1:0] myinputd;
    reg muxValid_d;
    reg muxValid_f;
    reg addr=0;
   //Loading weight values into the momory
    always @(posedge clk)
    begin
        if(rst)
        begin
            w_addr <= {addressWidth{1'b1}};
            wen <=0;
        end
        else if(weightValid & (config_layer_num==layerNo) & (config_neuron_num==neuronNo))
        begin
            w_in <= weightValue;
            w_addr <= w_addr + 1;
            wen <= 1;
        end
        else
            wen <= 0;
    end
	
    assign mux_valid = mult_valid;
    assign comboAdd = mul + sum;
    assign BiasAdd = bias + sum;
    assign ren = myinputValid;
    
	`ifdef pretrained
		initial
		begin
			$readmemb(biasFile,biasReg);
		end
		always @(posedge clk)
		begin
            // bias <= {biasReg[addr][dataWidth-1:0],{dataWidth{1'b0}}}; // ORIGINAL (can't add q2dec('bias',0,31,"bin") with q2dec('sum',1,30,"bin"))
            bias <= {1'b0,biasReg[addr][dataWidth-1:0],{(dataWidth-1){1'b0}}};
            // bias <= {biasReg[addr][dataWidth-1],biasReg[addr][dataWidth-1:0],{(dataWidth-1){1'b0}}};
        end
	`else
		always @(posedge clk)
		begin
			if(biasValid & (config_layer_num==layerNo) & (config_neuron_num==neuronNo))
			begin
                // bias <= {biasValue[dataWidth-1:0],{dataWidth{1'b0}}}; // ORIGINAL
                bias <= {1'b0,biasValue[dataWidth-1:0],{dataWidth{1'b0}}}; 
                // bias <= {biasReg[addr][dataWidth-1],biasValue[dataWidth-1:0],{dataWidth{1'b0}}}; 
			end
		end
	`endif
    
    
    always @(posedge clk)
    begin
        if(rst|outvalid)begin
            r_addr <= 0;
        end
        else if(myinputValid)begin
            r_addr <= r_addr + 1;
        end
    end
    
    always @(posedge clk)
    begin
        mul  <= $signed(myinputd) * $signed(w_out); // for 1 bit int part of weights and inputs we only need mul[30:15]
    end
    
    always @(posedge clk)
    begin
        if(rst|outvalid)
            sum <= 0;
        else if((r_addr == numWeight) & muxValid_f)
        begin
            if(!bias[2*dataWidth-1] &!sum[2*dataWidth-1] & BiasAdd[2*dataWidth-1]) //If bias and sum are positive and after adding bias to sum, if sign bit becomes 1, saturate
            begin
                sum[2*dataWidth-1] <= 1'b0;
                sum[2*dataWidth-2:0] <= {2*dataWidth-1{1'b1}};
            end
            else if(bias[2*dataWidth-1] & sum[2*dataWidth-1] &  !BiasAdd[2*dataWidth-1]) //If bias and sum are negative and after addition if sign bit is 0, saturate
            begin
                sum[2*dataWidth-1] <= 1'b1;
                sum[2*dataWidth-2:0] <= {2*dataWidth-1{1'b0}};
            end
            else
                sum <= BiasAdd; 
        end
        else if(mux_valid)
        begin
            if(!mul[2*dataWidth-1] & !sum[2*dataWidth-1] & comboAdd[2*dataWidth-1])
            begin
                sum[2*dataWidth-1] <= 1'b0;
                sum[2*dataWidth-2:0] <= {2*dataWidth-1{1'b1}};
            end
            else if(mul[2*dataWidth-1] & sum[2*dataWidth-1] & !comboAdd[2*dataWidth-1])
            begin
                sum[2*dataWidth-1] <= 1'b1;
                sum[2*dataWidth-2:0] <= {2*dataWidth-1{1'b0}};
            end
            else
                sum <= comboAdd; 
        end
        // if(sum!=0)$display("&&&&&&&&&&&  sum = %b",sum);
    end
    
    always @(posedge clk)
    begin
        myinputd <= myinput;
        weight_valid <= myinputValid;
        mult_valid <= weight_valid;
        sigValid <= ((r_addr == numWeight) & muxValid_f) ? 1'b1 : 1'b0;
        outvalid <= sigValid;
        muxValid_d <= mux_valid;
        muxValid_f <= !mux_valid & muxValid_d;
    end
    
    
    //Instantiation of Memory for Weights
    Weight_Memory #(.numWeight(numWeight),.neuronNo(neuronNo),.layerNo(layerNo),.addressWidth(addressWidth),.dataWidth(dataWidth),.weightFile(weightFile)) WM(
        .clk(clk),
        .wen(wen),
        .ren(ren),
        .wadd(w_addr),
        .radd(r_addr),
        .win(w_in),
        .wout(w_out)
    );
    
    generate
        if(actType == "sigmoid")
        begin:siginst
        //Instantiation of ROM for sigmoid
            Sig_ROM #(.inWidth(sigmoidSize),.dataWidth(dataWidth)) s1(
            .clk(clk),
            .x(sum[2*dataWidth-1-:sigmoidSize]),
            .out(out)
        );
        end
        else if(actType == "regression")
        begin:regrinst
            Regression #(.dataWidth(dataWidth),.weightIntWidth(weightIntWidth)) s1 (
            .clk(clk),
            .x(sum),
            .out(out)
        );
        end
        else
        begin:ReLUinst
            ReLU #(.dataWidth(dataWidth),.weightIntWidth(weightIntWidth)) s1 (
            .clk(clk),
            .x(sum),
            .out(out)
        );
        end
    endgenerate

    `ifdef DEBUG
    always @(posedge clk)
    begin
        if(outvalid)
            $display(neuronNo,,,,"%b ================================",out);
    end
    `endif

    // write .csv file
    integer waves;
    initial begin 
        waves = $fopen("test_regression/output_files/waves.csv");
        forever #1 $fwrite(waves,"%b,%b,%b,%b,%b,%b,%b\n", bias, BiasAdd, myinputd, w_out, mul, comboAdd, sum);
    end

    initial begin 
    $dumpfile("test_regression/output_files/dump_neuron.vcd");
    $dumpvars(outvalid);
    #30000
    $finish;
    end
endmodule
