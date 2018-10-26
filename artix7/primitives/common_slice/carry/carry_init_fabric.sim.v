(*blackbox*)
module CARRY_INIT_FABRIC(O, CO_CHAIN, CO_FABRIC, CI_FABRIC, DI, S);
  (* DELAY_CONST_CI_FABRIC="10e-12" *)
  (* DELAY_CONST_S="10e-12" *)
  output wire O;

  (* DELAY_CONST_CI_FABRIC="10e-12" *)
  (* DELAY_CONST_DI="10e-12" *)
  (* DELAY_CONST_S="10e-12" *)
  output wire CO_CHAIN, CO_FABRIC;
  input wire CI_FABRIC, DI, S;

  assign CO_CHAIN = S ? CI_FABRIC : DI;
  assign CO_FABRIC = CO_CHAIN;
  assign O = CI_FABRIC ^ S;
endmodule
