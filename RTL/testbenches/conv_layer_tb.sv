module conv_layer_tb ();

    parameter CLOCK_PERIOD = 100;
    
    parameter INPUT_LAYER_HEIGHT=4;
    parameter KERNEL_HEIGHT=3;
    parameter KERNEL_WIDTH=2;
    parameter WORD_SIZE=16;

    // control variables
    logic clk_i;
    logic reset_i;
    
    // input variables
    logic start_i;
    logic [INPUT_LAYER_HEIGHT-1:0][KERNEL_WIDTH-1:0][WORD_SIZE-1:0] data_i;
    
    logic done_o;
    logic [INPUT_LAYER_HEIGHT - KERNEL_HEIGHT:0][WORD_SIZE-1:0] data_o;

    assign data_i = '0; // temporary, awaiting convolutional node implementation

    conv_layer #(
        .INPUT_LAYER_HEIGHT(INPUT_LAYER_HEIGHT),
        .KERNEL_HEIGHT(KERNEL_HEIGHT),
        .KERNEL_WIDTH(KERNEL_WIDTH),
        .WORD_SIZE(WORD_SIZE),
        .MEM_INIT("conv_node_test.mif")
    ) DUT (.*);
    
    initial begin
        clk_i = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk_i = ~clk_i;
    end

    // goal: to ensure memory and control signals are iterating properly
    initial begin
        data_i  <= 128'h0003_0001_0001_0001_0002_0002_0001_0002; // output should be 2d_2f
        reset_i <= 1'b1;            @(posedge clk_i);
        reset_i <= 1'b0;            @(posedge clk_i);
        start_i <= 1'b1;            @(posedge clk_i);
        start_i <= 1'b0; repeat(15) @(posedge clk_i);
        start_i <= 1'b1;            @(posedge clk_i);
        start_i <= 1'b0; repeat(15) @(posedge clk_i);
        $stop;
    end

endmodule