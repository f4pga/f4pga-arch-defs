add_xc7_arch_define(
  ARCH artix7
  ROI_PART xc7a50tfgg484-1
  # -flatten is used to ensure that the output eblif has only one module.
  # Some of symbiflow expects eblifs with only one module.
  #
  # opt -undriven makes sure all nets are driven, if only by the $undef
  # net.
  YOSYS_SCRIPT "synth_xilinx -vpr -flatten $<SEMICOLON> opt_expr -undriven $<SEMICOLON> opt_clean"
)

add_subdirectory(tiles)
add_subdirectory(devices)
