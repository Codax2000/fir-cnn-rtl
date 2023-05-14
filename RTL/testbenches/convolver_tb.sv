`timescale 1ns / 1ps

module convolver_tb ();

    // TODO: Change test parameters as necessary
    parameter NUM_TESTS = 100;

    // TODO: Set any necessary model parameters here
    parameter INPUT_LAYER_HEIGHT = 128; // 60 samples, 2 '0' elements on either side  256 32
    parameter OUTPUT_LAYER_HEIGHT = 10;
    parameter WORD_SIZE = 16;
    parameter INT_BITS = 4;
    
    
    parameter CLOCK_PERIOD = 2;

    // control variables
    logic clk_i, reset_i, start_i;
    
    // input handshake
    logic [INPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] data_i;
    logic valid_i, ready_o;

    // output handshake
    logic valid_o, yumi_i;
    logic signed [WORD_SIZE-1:0] data_o;

    // values for testing
    logic signed [INPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] test_inputs [NUM_TESTS-1:0];
    logic signed [OUTPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] expected_outputs [NUM_TESTS-1:0];
    logic signed [OUTPUT_LAYER_HEIGHT-1:0][WORD_SIZE-1:0] current_expected_output ;
    
    // fc output layer and single fifo model the async FIFO that the FPGA will be writing to
    logic signed [WORD_SIZE-1:0] serial_out, fifo_out;
    logic signed [16:0][WORD_SIZE-1:0] conv_out;
    logic [5:0] conv_size_out;
    logic full, empty, wen, ren, conv_valid_lo, piso_ready_lo;

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

    double_fifo #(
        .WORD_SIZE(WORD_SIZE)
    ) input_fifo (
        .clk_i,
        .reset_i,
        
        .wen_i(wen),
        .full_o(full),
        .data_i(serial_out),

        
        .ren_i(ren),
        .data_o(fifo_out),
        .empty_o(empty)
    );

    convolve #(
        .WORD_SIZE(WORD_SIZE),
        .INT_BITS(INT_BITS),
        .INPUT_LAYER_HEIGHT(INPUT_LAYER_HEIGHT),
        .KERNEL_HEIGHT(16),
        .KERNEL_WIDTH(1),

        .LAYER_NUMBER(0),
        .CONVOLUTION_NUMBER(0)
    ) DUT (
        .clk_i,
        .reset_i,

        .start_i,

        .data_i(fifo_out),
        .ready_o(ren),
        .valid_i(!empty),

        .data_o(conv_out),
        .valid_o(conv_valid_lo),
        .ready_i(piso_ready_lo),
        .data_size_o(conv_size_out)
    );
    
    piso_layer #(
        .MAX_INPUT_SIZE(16+1),
        .WORD_SIZE(WORD_SIZE)
    ) piso (
        // top-level control
        .clk_i,
        .reset_i,
        
        // helpful handshake to prev layer
        .valid_i(conv_valid_lo),
        .ready_o(piso_ready_lo),
        .data_i(conv_out),
        .data_size_i(conv_size_out),
    
        // helpful handshake to next layer
        .valid_o,
        .ready_i(yumi_i),
        .data_o
    );
    
    
    initial begin
        clk_i = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk_i = ~clk_i;
    end


    // testbench loop
    int measured_outputs, errors;
    initial begin
        $readmemh("test_inputs.mif", test_inputs);
        $readmemh("test_outputs_expected.mif", expected_outputs);
        
        // check these file paths and change them locally, or this will fail
//        measured_outputs = $fopen("C:/Users/alexk/Documents/Projects/fir-cnn-rtl/mem/test_values/test_outputs_actual.csv", "w");
//        errors = $fopen("C:/Users/alexk/Documents/Projects/fir-cnn-rtl/mem/test_values/test_outputs_errors.csv", "w");
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
                                        
//            for (int j = 0; j < OUTPUT_LAYER_HEIGHT-1; j++) begin
//                $fwrite(measured_outputs, "%h,", data_o[j]);
                
//                $fwrite(errors, "%f,", $itor(data_o[j])/(2.0**(WORD_SIZE-INT_BITS)) - $itor(current_expected_output[j])/(2.0**(WORD_SIZE-INT_BITS)));
//                $display("%b: %f-%f = %f,",current_expected_output[j],$itor(data_o[j])/(2.0**(WORD_SIZE-INT_BITS)),$itor(current_expected_output[j])/(2.0**(WORD_SIZE-INT_BITS)),$itor(data_o[j])/(2.0**(WORD_SIZE-INT_BITS)) - $itor(current_expected_output[j])/(2.0**(WORD_SIZE-INT_BITS)));
//            end
//            $fwrite(measured_outputs, "%h\n", data_o[OUTPUT_LAYER_HEIGHT-1]);
//            $fwrite(errors, "%f\n", $itor(data_o[OUTPUT_LAYER_HEIGHT-1])/(2.0**(WORD_SIZE-INT_BITS)) - $itor(current_expected_output[OUTPUT_LAYER_HEIGHT-1])/(2.0**(WORD_SIZE-INT_BITS)));
//            $display("%b: %f-%f = %f\n",current_expected_output[OUTPUT_LAYER_HEIGHT-1],$itor(data_o[OUTPUT_LAYER_HEIGHT-1])/(2.0**(WORD_SIZE-INT_BITS)),$itor(current_expected_output[OUTPUT_LAYER_HEIGHT-1])/(2.0**(WORD_SIZE-INT_BITS)),$itor(data_o[OUTPUT_LAYER_HEIGHT-1])/(2.0**(WORD_SIZE-INT_BITS)) - $itor(current_expected_output[OUTPUT_LAYER_HEIGHT-1])/(2.0**(WORD_SIZE-INT_BITS)));

            yumi_i <= 1'b1;             repeat(200) @(posedge clk_i);
            yumi_i <= 1'b0;             @(posedge clk_i);
        end

//        $fclose(measured_outputs);
//        $fclose(errors);

        $stop;
    end

endmodule