// To ensure that all DRAMs are co-located within a SLICE, this block is
// a simple passthrough black box to allow a pack pattern for dual port DRAMs.
(* lib_whitebox *)
module DRAM_8_OUTPUT_STUB(
    input DOA1, DOB1, DOC1, DOD1, DOA0, DOB0, DOC0, DOD0,
    output DOA1_OUT, DOB1_OUT, DOC1_OUT, DOD1_OUT, DOA0_OUT, DOB0_OUT, DOC0_OUT, DOD0_OUT
);
  (* DELAY_CONST_DOA1="0" *)
  wire DOA1_OUT;

  (* DELAY_CONST_DOB1="0" *)
  wire DOB1_OUT;

  (* DELAY_CONST_DOC1="0" *)
  wire DOC1_OUT;

  (* DELAY_CONST_DOD1="0" *)
  wire DOD1_OUT;

  (* DELAY_CONST_DOA0="0" *)
  wire DOA0_OUT;

  (* DELAY_CONST_DOB0="0" *)
  wire DOB0_OUT;

  (* DELAY_CONST_DOC0="0" *)
  wire DOC0_OUT;

  (* DELAY_CONST_DOD0="0" *)
  wire DOD0_OUT;

  assign DOA1_OUT = DOA1;
  assign DOB1_OUT = DOB1;
  assign DOC1_OUT = DOC1;
  assign DOD1_OUT = DOD1;
  assign DOA0_OUT = DOA0;
  assign DOB0_OUT = DOB0;
  assign DOC0_OUT = DOC0;
  assign DOD0_OUT = DOD0;
endmodule
