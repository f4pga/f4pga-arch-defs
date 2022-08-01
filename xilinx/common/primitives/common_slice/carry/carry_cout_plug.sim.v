// This CARRY_COUT_PLUG actually will form a molecule with the previous
// CARRY4 primative, and allow VPR to distiguish between the net
// connecting to the next CARRY4 and the general fabric.
(* lib_whitebox *)
module CARRY_COUT_PLUG(
    input CIN,
    output COUT
);
  (* DELAY_CONST_CIN="0" *)
  wire COUT;

  assign COUT = CIN;
endmodule

