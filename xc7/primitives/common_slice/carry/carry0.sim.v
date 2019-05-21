(* whitebox *)
module CARRY0_CONST(O, CO_CHAIN, CO_FABRIC, CI_INIT, CI, DI, S);
  (* DELAY_CONST_CI="10e-12" *)
  (* DELAY_CONST_CI_INIT="10e-12" *)
  (* DELAY_CONST_S="10e-12" *)
  output wire O;

  (* DELAY_CONST_CI="10e-12" *)
  (* DELAY_CONST_CI_INIT="10e-12" *)
  (* DELAY_CONST_DI="10e-12" *)
  (* DELAY_CONST_S="10e-12" *)
  output wire CO_CHAIN, CO_FABRIC;
  input wire CI_INIT, CI, DI, S;

  assign CI_COMBINE = CI | CI_INIT;
  assign CO_CHAIN = S ? CI_COMBINE : DI;
  assign CO_FABRIC = CO_CHAIN;
  assign O = CI_COMBINE ^ S;
endmodule
