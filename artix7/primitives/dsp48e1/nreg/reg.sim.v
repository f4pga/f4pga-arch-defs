module REG (D, Q, CLK, CE, RESET);
   input wire D;
   input wire CLK;
   input wire CE;
   input wire RESET;
   output reg Q;

   always @(posedge CLK) begin
     if (~RESET)
       Q <= 1'b0;
     else if (CE)
       Q <= D;
   end

endmodule // REG
