(*blackbox*)
module CARRY_INIT0(O, CO_CHAIN, CO_FABRIC, DI, S);
  (* DELAY_CONST_S="10e-12" *)
  output wire O;

  (* DELAY_CONST_DI="10e-12" *)
  (* DELAY_CONST_S="10e-12" *)
  output wire CO_CHAIN, CO_FABRIC;
  input wire DI, S;

  wire CI_INIT;
  assign CI_INIT = 0;

  assign CO_CHAIN = S ? CI_INIT : DI;
  assign CO_FABRIC = CO_CHAIN;
  assign O = CI_INIT ^ S;
endmodule

