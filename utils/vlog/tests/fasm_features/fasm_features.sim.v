(* blackbox *)
(* FASM_PREFIX = "MY_CELL" *)
(* FASM_FEATURES = "USE_SOMETHING" *)
(* FASM_LUT = "XLUT.INIT[7:0] = XLUT[0]; XLUT.INIT[15:8] = XLUT[1]" *)
module fasm_features (
  input  wire I,
  output wire O
);

assign O = I;

endmodule

