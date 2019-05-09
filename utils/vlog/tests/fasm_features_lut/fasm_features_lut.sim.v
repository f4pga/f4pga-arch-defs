(* blackbox *)
(* CLASS = "lut" *)
(* FASM_TYPE = "LUT" *)
(* FASM_LUT = "FASM_FEATURES_LUT.INIT[1:0] = XLUT[0] FASM_FEATURES_LUT.INIT[3:2] = XLUT[1]" *)
module fasm_features_lut (I0, I1, I2, I3, O);
  input  wire I0;
  input  wire I1;
  input  wire I2;
  input  wire I3;
  output wire O;

  parameter [15:0] INIT = 0;

  assign O = INIT[{I3,I2,I1,I0}];

endmodule

