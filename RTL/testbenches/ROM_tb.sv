module ROM_tb ();

    logic clk_i;
    logic [2:0] addr_i;
    logic [7:0] data_o;

    logic [3:0] x;
    logic [3:0] y;
    logic [7:0] product;
    
    assign x = 4'b0111;
    assign y = 4'h7;
    assign product = x * y;

    parameter CLOCK_PERIOD = 100;
    
    initial begin
        clk_i = 1'b1;
        forever # (CLOCK_PERIOD / 2) clk_i = ~clk_i;
    end

    ROM DUT (.*);

    integer i;
    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            addr_i <= i;
            repeat(2) @(posedge clk_i);
        end
        
        $stop;
    end

endmodule