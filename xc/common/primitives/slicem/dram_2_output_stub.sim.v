// To ensure that all DRAMs are co-located within a SLICE, this block is
// a simple passthrough black box to allow a pack pattern for dual port DRAMs.
(* lib_whitebox *)
module DRAM_2_OUTPUT_STUB(
    input SPO, DPO,
    output SPO_OUT, DPO_OUT
);
  (* DELAY_CONST_SPO="0" *)
  wire SPO_OUT;

  (* DELAY_CONST_DPO="0" *)
  wire DPO_OUT;
  assign SPO_OUT = SPO;
  assign DPO_OUT = DPO;
endmodule
