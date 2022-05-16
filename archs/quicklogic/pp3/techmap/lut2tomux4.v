// In EOS S3 / PP3 2-input LUTs are actually mapped to muxes that select from
// 0s and 1s according to the LUT configuration. This techmap does that explicitly
// by converting LUT2 to mux4x0.
module LUT2 (
  output O,
  input  I0,
  input  I1
);
  parameter [3:0] INIT = 0;
  parameter EQN = "(I0)";

  wire XA1 = INIT[0];
  wire XA2 = INIT[1];
  wire XB1 = INIT[2];
  wire XB2 = INIT[3];

  mux4x0 _TECHMAP_REPLACE_ (
  .A  (XA1),
  .B  (XA2),
  .C  (XB1),
  .D  (XB2),
  .S1 (I1),
  .S0 (I0),
  .Q  (O)
  );

endmodule
