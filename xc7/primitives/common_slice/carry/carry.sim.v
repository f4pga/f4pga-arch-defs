(* whitebox *)
module CARRY(O, CO_CHAIN, CO_FABRIC, CI, DI, S);
  (* DELAY_CONST_CI="10e-12" *)
  (* DELAY_CONST_S="10e-12" *)
  output wire O;

  (* DELAY_CONST_CI="10e-12" *)
  (* DELAY_CONST_DI="10e-12" *)
  (* DELAY_CONST_S="10e-12" *)
  output wire CO_CHAIN, CO_FABRIC;
  input wire CI, DI, S;

  assign CO_CHAIN = S ? CI : DI;
  assign CO_FABRIC = CO_CHAIN;
  assign O = CI ^ S;
endmodule
