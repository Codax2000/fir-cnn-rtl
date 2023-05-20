`timescale 1ns / 1ps

`include "test_regression/include.v"
`include "test_regression/zynet.v"

module top_sim();
    reg reset;
    reg clock;
    reg [`dataWidth-1:0] in;
    reg in_valid;
    reg [`dataWidth-1:0] in_mem [`numData-1:0];
    reg [`dataWidth-1:0] res_mem [`numNeuronLayer1-1:0];
    reg [7:0] fileName[33:0];
    reg s_axi_awvalid;
    reg [31:0] s_axi_awaddr;
    wire s_axi_awready;
    reg [31:0] s_axi_wdata;
    reg s_axi_wvalid;
    wire s_axi_wready;
    wire s_axi_bvalid;
    reg s_axi_bready;
    wire intr;
    reg [31:0] axiRdData;
    reg [31:0] s_axi_araddr;
    wire [31:0] s_axi_rdata;
    reg s_axi_arvalid;
    wire s_axi_arready;
    wire s_axi_rvalid;
    reg s_axi_rready;
    reg [`dataWidth-1:0] expected;

    wire [31:0] numNeurons[31:1];
    wire [31:0] numWeights[31:1];
    
    assign numNeurons[1] = `numNeuronLayer1;
    
    assign numWeights[1] = `numWeightLayer1;
    
    integer right=0;
    
    zyNet dut(
    .s_axi_aclk(clock),
    .s_axi_aresetn(reset),
    .s_axi_awaddr(s_axi_awaddr),
    .s_axi_awprot(3'b000),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),
    .s_axi_wdata(s_axi_wdata),
    .s_axi_wstrb(4'hF),
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wready(s_axi_wready),
    .s_axi_bresp(),
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bready(s_axi_bready),
    .s_axi_araddr(s_axi_araddr),
    .s_axi_arprot(3'b000),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),
    .s_axi_rdata(s_axi_rdata),
    .s_axi_rresp(),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready),
    .axis_in_data(in),
    .axis_in_data_valid(in_valid),
    .axis_in_data_ready(),
    .intr(intr)
    );
                
    initial
    begin
        clock = 1'b0;
        s_axi_awvalid = 1'b0;
        s_axi_bready = 1'b0;
        s_axi_wvalid = 1'b0;
        s_axi_arvalid = 1'b0;
    end
        
    always
        #5 clock = ~clock;

    function [7:0] to_ascii;
        input integer a;
        begin
        to_ascii = a+48;
        end
    endfunction
    
    always @(posedge clock)
    begin
        s_axi_bready <= s_axi_bvalid;
        s_axi_rready <= s_axi_rvalid;
    end
    
    task writeAxi(
        input [31:0] address,
        input [31:0] data
        );
        begin
            @(posedge clock);
            s_axi_awvalid <= 1'b1;
            s_axi_awaddr <= address;
            s_axi_wdata <= data;
            s_axi_wvalid <= 1'b1;
            wait(s_axi_wready);
            @(posedge clock);
            s_axi_awvalid <= 1'b0;
            s_axi_wvalid <= 1'b0;
            @(posedge clock);
        end
    endtask
    
    task readAxi(
        input [31:0] address
        );
        begin
            @(posedge clock);
            s_axi_arvalid <= 1'b1;
            s_axi_araddr <= address;
            wait(s_axi_arready);
            @(posedge clock);
            s_axi_arvalid <= 1'b0;
            wait(s_axi_rvalid);
            @(posedge clock);
            axiRdData <= s_axi_rdata;
            @(posedge clock);
        end
    endtask
    
    task configWeights();
        integer i,j,k,t;
        integer neuronNo_int;
        reg [`dataWidth-1:0] config_mem [`numWeightLayer1-1:0];
        begin
            @(posedge clock);
            for(k=1;k<=`numLayers;k=k+1)
            begin
                writeAxi(12,k);//Write layer number
                for(j=0;j<numNeurons[k];j=j+1)
                begin
                    $display("%s",{"Loading weights w_",to_ascii(k),"_",to_ascii(j),".mif"});
                    $readmemb({"test_regression/weights/w_",to_ascii(k),"_",to_ascii(j),".mif"}, config_mem);
                    writeAxi(16,j);//Write neuron number
                    for (t=0; t<numWeights[k]; t=t+1) begin
                        // $display("%s",{"Loading weight ",to_ascii(t)," out of ",to_ascii(numWeights[k]-1)});
                        // $display("%b",{15'd0,config_mem[t]});
                        writeAxi(0,{15'd0,config_mem[t]});
                    end 
                end
            end
        end
    endtask
    
    task configBias();
        integer i,j,k,t;
        integer neuronNo_int;
        reg [31:0] bias[0:0];
        begin
            @(posedge clock);
            for(k=1;k<=`numLayers;k=k+1)
            begin
                writeAxi(12,k);//Write layer number
                for(j=0;j<numNeurons[k];j=j+1)
                begin
                    $display("%s",{"Loading bias b_",to_ascii(k),"_",to_ascii(j),".mif"});
                    $readmemb({"test_regression/biases/b_",to_ascii(k),"_",to_ascii(j),".mif"}, bias);
                    writeAxi(16,j);//Write neuron number
                    // $display("%b",{15'd0,bias[0]});
                    writeAxi(4,{15'd0,bias[0]});
                end                
            end
        end
    endtask
    
    task sendData(input integer testDataCount);
        integer t;
        begin
            if(testDataCount<10) begin
                // $display("--- %s %s",{"test_regression/test_data/test_data_000",to_ascii(testDataCount),".txt"},{"loaded successfully!"});
                $readmemb({"test_regression/test_data/test_data_000",to_ascii(testDataCount),".txt"}, in_mem);
                // $display("--- %s %s",{"test_regression/results/results_000",to_ascii(testDataCount),".txt"},{"loaded successfully!"});
                $readmemb({"test_regression/results/results_000",to_ascii(testDataCount),".txt"}, res_mem);
            end
            else if(testDataCount<100) begin
                // $display("--- %s %s",{"test_regression/test_data/test_data_00",to_ascii(testDataCount),".txt"},{"loaded successfully!"});
                $readmemb({"test_regression/test_data/test_data_00",to_ascii(testDataCount),".txt"}, in_mem);
                // $display("--- %s %s",{"test_regression/results/results_00",to_ascii(testDataCount),".txt"},{"loaded successfully!"});
                $readmemb({"test_regression/results/results_00",to_ascii(testDataCount),".txt"}, res_mem);
            end
            else if(testDataCount<1000) begin
                // $display("--- %s %s",{"test_regression/test_data/test_data_0",to_ascii(testDataCount),".txt"},{"loaded successfully!"});
                $readmemb({"test_regression/test_data/test_data_0",to_ascii(testDataCount),".txt"}, in_mem);
                // $display("--- %s %s",{"test_regression/results/results_0",to_ascii(testDataCount),".txt"},{"loaded successfully!"});
                $readmemb({"test_regression/results/results_0",to_ascii(testDataCount),".txt"}, res_mem);
            end
            else begin
                // $display("--- %s %s",{"test_regression/test_data/test_data_",to_ascii(testDataCount),".txt"},{"loaded successfully!"});
                $readmemb({"test_regression/test_data/test_data_",to_ascii(testDataCount),".txt"}, in_mem);
                // $display("--- %s %s",{"test_regression/results/results_",to_ascii(testDataCount),".txt"},{"loaded successfully!"});
                $readmemb({"test_regression/results/results_",to_ascii(testDataCount),".txt"}, res_mem);
            end
            @(posedge clock);
            @(posedge clock);
            @(posedge clock);
            for (t=0; t <`numData; t=t+1) begin
                @(posedge clock)begin
                    in <= in_mem[t]; // in == data going into the NN serially (from test_data_0000 each line of the 784 lines at a time)
                    in_valid <= 1;
                end
                // @(negedge clock)in_valid <= 0;
            end 
            @(posedge clock);
            in_valid <= 0;
            expected = res_mem[0];
        end
    endtask
   
    integer i,j,layerNo=1,k;
    integer start;
    integer testDataCount;
    integer testDataCount_int;
    initial
    begin
        reset = 0;
        in_valid = 0;
        #50;
        reset = 1;
        #100
        writeAxi(28,0); //clear soft reset
        start = $time;
        if(`pretrained==1)begin
            // $display("--- Pretrained... Fetching weights and biases... Configuring NN...");
            configWeights();
            configBias();
        end
        // $display("--- Configuration completed",,,,$time-start,,"ns");

        // $display("--- Feeding data in NN...");
        start = $time;
        for(testDataCount=0;testDataCount<`MaxTestSamples;testDataCount=testDataCount+1)
        begin
            sendData(testDataCount);
            @(posedge intr);
            // readAxi(24);
            // $display("Status: %0x",axiRdData);
            readAxi(8);

            if(axiRdData==expected)
                right = right+1;
            $display("%0d. Accuracy: %f, Detected number: %0b, Expected: %b",testDataCount+1,right*100.0/(testDataCount+1),axiRdData,expected);
            
            //                             ==============
            // I want to consider correct also the results that are very close to the expected.
            // using PYTHON to achieve this :) 
            // I am writing all the results in a csv file.
            $fwrite(waves,"%b,%b\n", expected, axiRdData[`dataWidth-1:0]);
            //                             ==============

            /*$display("Total execution time",,,,$time-start,,"ns");
            j=0;
            repeat(10)
            begin
                readAxi(20);
                $display("Output of Neuron %d: %0x",j,axiRdData);
                j=j+1;
            end*/
        end
        // $display("--- Accuracy: %f",right*100.0/testDataCount);
        // $stop;
        $finish;
    end



// write .csv file
integer waves;
initial begin 
    waves = $fopen("test_regression/output_files/results.csv");
    // forever #1 $fwrite(waves,"%b,%b\n", expected, axiRdData);
end

// dump waveforms
initial begin 
    $dumpfile("test_regression/output_files/dump.vcd");
    $dumpvars(1);
end

endmodule