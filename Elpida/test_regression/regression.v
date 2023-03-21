module Regression  #(parameter dataWidth=16,weightIntWidth=4) (
    input           clk,
    input   [2*dataWidth-1:0]   x,
    output  reg [dataWidth-1:0]  out
);


always @(posedge clk)
begin
    if(|x[2*dataWidth-1-:weightIntWidth+1]) //over flow to sign bit of integer part  ---- numOfInputBits > numOfOutputBits
            out <= {1'b0,{(dataWidth-1){1'b1}}}; //positive saturate
        else
            out <= x[2*dataWidth-1-weightIntWidth-:dataWidth];     
end

endmodule