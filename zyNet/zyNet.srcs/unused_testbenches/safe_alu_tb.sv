
module safe_alu_tb ();
  logic[5:0]x;
  
  parameter WORD_SIZE = 4;
  parameter N_SIZE = 2;
  
  logic signed [WORD_SIZE-1:0] a_i,b_i,data_o;
  
  safe_alu #(.WORD_SIZE(WORD_SIZE),
         .N_SIZE(N_SIZE),
         .OPERATION("mult")) DUT (.*);
  
  initial begin
    for (int i = 0; i < 2**WORD_SIZE; i++) begin
      for (int j = 0; j < 2**WORD_SIZE; j++) begin
        a_i = i; b_i = j; #1
        $display("%b * %b = %b",a_i, b_i, data_o);
        $display("%f * %f = %f",$itor(a_i)/(2.0**N_SIZE), $itor(b_i)/(2.0**N_SIZE), $itor(data_o)/(2.0**N_SIZE));
      end
    end
    
    $stop;
  end
  
endmodule