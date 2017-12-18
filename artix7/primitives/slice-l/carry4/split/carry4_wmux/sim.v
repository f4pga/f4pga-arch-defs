module MUXCY(O, CI, DI, S);
  output wire O;
  input wire CI;
  input wire DI;
  input wire S;

  assign O = S ? CI : DI;
endmodule
