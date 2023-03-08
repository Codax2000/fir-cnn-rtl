/**
Alex Knowlton
Single-port synchronous ROM
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
    
    assign data_o = mem[addr_i];
    
endmodule