`timescale 1ns / 1ps

module bn_layer_tb ();
    
    parameter CLOCK_PERIOD = 10;
    parameter INPUT_SIZE=256;
    parameter WORD_SIZE=16;
    parameter N_SIZE=12;
    parameter LAYER_NUM=0;
    
    parameter NUM_TESTS = 7176*INPUT_SIZE;
    parameter INPUT_LAYER_HEIGHT = 1; // 60 samples, 2 '0' elements on either side  256 32
    parameter OUTPUT_LAYER_HEIGHT = 1;
    parameter INT_BITS = 4;
    
    
    
    
    
// LOGIC SIGNALS

    // control variables
    logic clk_i, reset_i, start_i;
    
    // input handshake
    logic [WORD_SIZE-1:0] data_i;
    logic valid_i, ready_o;

    // output handshake
    logic valid_o, yumi_i;
    logic signed [WORD_SIZE-1:0] data_o;

    // values for testing
    logic signed [WORD_SIZE-1:0] test_inputs [NUM_TESTS-1:0];
    logic signed [WORD_SIZE-1:0] expected_outputs [NUM_TESTS-1:0];
    logic signed [WORD_SIZE-1:0] current_expected_output ;
    
    // fc output layer and single fifo model the async FIFO that the FPGA will be writing to
    logic [WORD_SIZE-1:0] fifo_out;
    logic empty, ren;
    
    
    
    
    
// DATAPATH

    single_fifo #(
        .WORD_SIZE(WORD_SIZE)
    ) input_fifo (
        .clk_i,
        .reset_i,

        
        .wen_i(valid_i),
        .full_o(ready_o),
        .data_i(data_i),

        
        .ren_i(ren),
        .data_o(fifo_out),
        .empty_o(empty)
    );

    bn_layer #(.INPUT_SIZE(INPUT_SIZE),
               .WORD_SIZE(WORD_SIZE),
               .N_SIZE(N_SIZE),
               .LAYER_NUMBER(0),
               .MEM_WORD_SIZE(21)
    ) DUT (        
        // top level control
        .clk_i,
        .reset_i,
        
        // handshake to prev layer
        .ready_o(ren),
        .valid_i(!empty),
        .data_r_i(fifo_out),
        
        // handshake to next layer
        .valid_o,
        .ready_i(yumi_i),
        .data_r_o(data_o)
    );
    
    
    
    
    
// TESTBENCH

    initial begin
        clk_i = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk_i = ~clk_i;
    end

    int measured_outputs, errors;
    initial begin
        $readmemh("test_bn_inputs.mif", test_inputs);
        $readmemh("test_bn_outputs_expected.mif", expected_outputs);
        measured_outputs = $fopen("C:/Users/eugli/Documents/GitHub/fir-cnn-rtl/mem/test_values/test_bn_outputs_actual.csv", "w");
        errors = $fopen("C:/Users/eugli/Documents/GitHub/fir-cnn-rtl/mem/test_values/test_bn_output_error.csv", "w");
        
        reset_i <= 1'b1;
        valid_i <= 1'b0;
        start_i <= 1'b0;
        yumi_i <= 1'b0;     @(posedge clk_i); @(posedge clk_i);
        reset_i <= 1'b0;    @(posedge clk_i);
        for (int i = 0; i < NUM_TESTS; i++) begin
            $display("Running test %d",i);
            current_expected_output <= expected_outputs[i];
            data_i <= test_inputs[i];   @(posedge clk_i);
            valid_i <= 1'b1;            @(posedge clk_i);
            valid_i <= 1'b0;            @(posedge valid_o);
                                        @(posedge clk_i);
                                        

            $fwrite(measured_outputs, "%h\n", data_o);
            $fwrite(errors, "%f\n", $itor(data_o)/(2.0**(WORD_SIZE-INT_BITS)) - $itor(current_expected_output)/(2.0**(WORD_SIZE-INT_BITS)));
            $display("%f-%f = %f\n",$itor(data_o)/(2.0**(WORD_SIZE-INT_BITS)),$itor(current_expected_output)/(2.0**(WORD_SIZE-INT_BITS)),$itor(data_o)/(2.0**(WORD_SIZE-INT_BITS)) - $itor(current_expected_output)/(2.0**(WORD_SIZE-INT_BITS)));

            yumi_i <= 1'b1;             @(posedge clk_i);
            yumi_i <= 1'b0;             @(posedge clk_i);
        end

        $fclose(measured_outputs);
        $fclose(errors);

        $stop;
    end
    
endmodule
