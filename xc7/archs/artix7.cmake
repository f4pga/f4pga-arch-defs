project_xray_prepare_database(
  PART artix7
)

add_xc7_arch_define(
  ARCH artix7
  ROI_PART "xc7a35tcpg236-1"
  ROI_DIR "${PRJXRAY_DB_DIR}/artix7/harness/basys3/swbut"
  # -flatten is used to ensure that the output eblif has only one module.
  # Some of symbiflow expects eblifs with only one module.
  #
  # opt -undriven makes sure all nets are driven, if only by the $undef
  # net.
  YOSYS_SCRIPT "synth_xilinx -vpr -flatten $<SEMICOLON> opt_expr -undriven $<SEMICOLON> opt_clean"
)
