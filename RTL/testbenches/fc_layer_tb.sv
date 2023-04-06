module fc_layer_tb ();

    fc_output_layer #(

    ) input_layer (

    );

    double_fifo #(

    ) input_fifo (

    );

    fc_layer #(

    ) DUT (

    );

    fc_output_layer #(

    ) output_layer (

    );

    double_fifo #(

    ) output_fifo (

    );

    parameter CLOCK_PERIOD = 100;
    initial begin
        clk_i = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk_i = ~clk_i;
    end

    // manipulate ren_i, data_i, valid_i,
    initial begin
        data_i <= 32'haf_10_14_36; // test case 1
        reset_i <= 1'b1; @(posedge clk_i);

        data_i <= 32'h11_01_a1_11; // test case 2
        $stop;
    end

endmodule