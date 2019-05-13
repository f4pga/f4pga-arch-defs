(* blackbox *)
(* FASM_FEATURES = "MY_FASM_FEATURE_A MY_FASM_FEATURE_B" *)
module fasm_features (I, O);
  input  wire I;
  output wire O;

 assign O = I;

endmodule

