// Simple passthrough box to for DI mux selection on dual port DRAMs.
(* lib_whitebox *)
module DI64_STUB(
    input DI,
    output DO
);
  (* DELAY_CONST_DI="0" *)
  wire DO;

  assign DO = DI;
endmodule
