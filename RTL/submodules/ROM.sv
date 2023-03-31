/**
Alex Knowlton
Single-port synchronous ROM

In Vivado, give name of init file, not relative path. Vivado will handle the relative pathing

parameters:
    depth: number of bits in address
    width: number of bits in output data
    init_file: name of mif file for initialization (coe file not tested but will likely not work)
*/

module ROM #(parameter depth=3, width=8, init_file="fc_node_test.mif") (
    input  logic clk_i,
    input  logic [depth-1:0] addr_i,
    output logic [width-1:0] data_o
    );
    
    logic [width-1:0] mem [2**depth-1:0];
	
	initial begin
		$readmemh(init_file,mem);
	end
    
    always_ff @(posedge clk_i) begin
        data_o <= mem[addr_i];
    end
    
endmodule