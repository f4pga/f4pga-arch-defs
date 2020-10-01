// To ensure that all DRAMs are co-located within a SLICE, this block is
// a simple passthrough black box to allow a pack pattern for dual port DRAMs.
(* lib_whitebox *)
module DRAM_4_OUTPUT_STUB(
    input DOA, DOB, DOC, DOD,
    output DOA_OUT, DOB_OUT, DOC_OUT, DOD_OUT
);
  (* DELAY_CONST_DOA="0" *)
  wire DOA_OUT;

  (* DELAY_CONST_DOB="0" *)
  wire DOB_OUT;

  (* DELAY_CONST_DOC="0" *)
  wire DOC_OUT;

  (* DELAY_CONST_DOD="0" *)
  wire DOD_OUT;

  assign DOA_OUT = DOA;
  assign DOB_OUT = DOB;
  assign DOC_OUT = DOC;
  assign DOD_OUT = DOD;
endmodule
