module fdse (DIN, CE, CLK, S, OUT);
 (* SDF_ALIAS = "D" *)
 input  wire DIN;
 input  wire CE;
 input  wire CLK;
 (* SDF_ALIAS = "SR" *)
 input  wire S;
 (* SDF_ALIAS = "Q" *)
 output reg  OUT;

 always @(posedge CLK or posedge S)
  if      (S)   OUT <= 1'd0;
  else if (CE)  OUT <= DIN;

endmodule
