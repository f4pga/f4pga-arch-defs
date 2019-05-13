(* blackbox *)
(* CLASS = "lut" *)
(* FASM_TYPE = "LUT" *)
(* FASM_LUT = "FASM_FEATURES_LUT.INIT[1:0] = XLUT[0] FASM_FEATURES_LUT.INIT[3:2] = XLUT[1]" *)
module fasm_features_lut (I, O);
  input  wire [3:0] I;
  output wire O;

  parameter [15:0] INIT = 0;

  assign O = INIT[I];

endmodule

