`timescale 1ns / 1ps

module gap_layer_tb ();
    
    parameter CLOCK_PERIOD = 10;
    parameter INPUT_SIZE=113;
    parameter WORD_SIZE=16;
    parameter N_SIZE=12;
    parameter NUM_TESTS = 7176;
    parameter INPUT_LAYER_HEIGHT = 113; // 60 samples, 2 '0' elements on either side  256 32
    parameter OUTPUT_LAYER_HEIGHT = 1;
    parameter INT_BITS = 4;
    
    // control variables
    logic clk_i, reset_i, start_i;
    
    // input handshake
    logic [INPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] data_i;
    logic valid_i, ready_o;

    // output handshake
    logic valid_o, yumi_i;
    logic signed [OUTPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] data_o;

    // values for testing
    logic signed [INPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] test_inputs [NUM_TESTS-1:0];
    logic signed [OUTPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] expected_outputs [NUM_TESTS-1:0];
    logic signed [OUTPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] current_expected_output ;
    
    // fc output layer and single fifo model the async FIFO that the FPGA will be writing to
    logic [WORD_SIZE-1:0] serial_out, fifo_out;
    logic full, empty, wen, ren;

    fc_output_layer #(
        .LAYER_HEIGHT(INPUT_LAYER_HEIGHT),
        .WORD_SIZE(WORD_SIZE) 
    ) input_serializer (
        .clk_i,
        .reset_i,
    
        // helpful handshake to prev layer
        .valid_i,
        .ready_o,
        .data_i,

        // demanding handshake to next layer
        .wen_o(wen),
        .full_i(full),
        .data_o(serial_out)
    );

    single_fifo #(
        .WORD_SIZE(WORD_SIZE)
    ) input_fifo (
        .clk_i,
        .reset_i,

        
        .wen_i(wen),
        .full_o(full),
        .data_i,

        
        .ren_i(ren),
        .data_o(fifo_out),
        .empty_o(empty)
    );

    gap_layer #(.INPUT_SIZE(INPUT_SIZE),
               .WORD_SIZE(WORD_SIZE),
               .N_SIZE(N_SIZE)
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
    
    initial begin
        clk_i = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk_i = ~clk_i;
    end

    // testbench loop
    int measured_outputs, errors;
    initial begin
        $readmemh("test_gap_inputs.mif", test_inputs);
        $readmemh("test_gap_outputs_expected.mif", expected_outputs);
        measured_outputs = $fopen("C:/Users/eugli/Documents/GitHub/fir-cnn-rtl/mem/test_values/test_gap_outputs_actual.csv", "w");
        errors = $fopen("C:/Users/eugli/Documents/GitHub/fir-cnn-rtl/mem/test_values/test_gap_output_error.csv", "w");
        
        reset_i <= 1'b1;
        start_i <= 1'b0;
        yumi_i <= 1'b0;     @(posedge clk_i); @(posedge clk_i);
        reset_i <= 1'b0;    @(posedge clk_i);
        for (int i = 0; i < NUM_TESTS; i++) begin
            $display("Running test %d",i);
            current_expected_output <= expected_outputs[i];
            data_i <= test_inputs[i];   @(posedge clk_i);
            valid_i <= 1'b1;            @(posedge clk_i);
            valid_i <= 1'b0;            @(posedge clk_i);
            start_i <= 1'b1;            @(posedge clk_i);
            start_i <= 1'b0;            @(posedge clk_i);
                                        @(posedge valid_o);
                                        @(posedge clk_i);
                                        
            for (int j = 0; j < OUTPUT_LAYER_HEIGHT-1; j++) begin
                $fwrite(measured_outputs, "%h,", data_o[j]);
                
                $fwrite(errors, "%f,", $itor(data_o[j])/(2.0**(WORD_SIZE-INT_BITS)) - $itor(current_expected_output[j])/(2.0**(WORD_SIZE-INT_BITS)));
                $display("%f-%f = %f,",$itor(data_o[j])/(2.0**(WORD_SIZE-INT_BITS)),$itor(current_expected_output[j])/(2.0**(WORD_SIZE-INT_BITS)),$itor(data_o[j])/(2.0**(WORD_SIZE-INT_BITS)) - $itor(current_expected_output[j])/(2.0**(WORD_SIZE-INT_BITS)));
            end
            $fwrite(measured_outputs, "%h\n", data_o[OUTPUT_LAYER_HEIGHT-1]);
            $fwrite(errors, "%f\n", $itor(data_o[OUTPUT_LAYER_HEIGHT-1])/(2.0**(WORD_SIZE-INT_BITS)) - $itor(current_expected_output[OUTPUT_LAYER_HEIGHT-1])/(2.0**(WORD_SIZE-INT_BITS)));
            $display("%f-%f = %f\n",$itor(data_o[OUTPUT_LAYER_HEIGHT-1])/(2.0**(WORD_SIZE-INT_BITS)),$itor(current_expected_output[OUTPUT_LAYER_HEIGHT-1])/(2.0**(WORD_SIZE-INT_BITS)),$itor(data_o[OUTPUT_LAYER_HEIGHT-1])/(2.0**(WORD_SIZE-INT_BITS)) - $itor(current_expected_output[OUTPUT_LAYER_HEIGHT-1])/(2.0**(WORD_SIZE-INT_BITS)));

            yumi_i <= 1'b1;             @(posedge clk_i);
            yumi_i <= 1'b0;             @(posedge clk_i);
        end

        $fclose(measured_outputs);
        $fclose(errors);

        $stop;
    end
    
endmodule
