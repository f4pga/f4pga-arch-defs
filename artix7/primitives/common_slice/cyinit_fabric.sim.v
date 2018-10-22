(*blackbox*)
module CYINIT_FABRIC(output CI_CHAIN, input CI_FABRIC);
  (* DELAY_CONST_CI_FABRIC="10e-12" *)
  wire CI_CHAIN;
  wire CI_FABRIC;

  assign CI_CHAIN = CI_FABRIC;
endmodule

