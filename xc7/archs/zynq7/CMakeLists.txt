add_xc7_arch_define(
  ARCH zynq7
  ROI_PART xc7z010clg400-1
  ROI_DIR ${PRJXRAY_DB_DIR}/zynq7/harness/zybo/swbut
  # -flatten is used to ensure that the output eblif has only one module.
  # Some of symbiflow expects eblifs with only one module.
  #
  # opt -undriven makes sure all nets are driven, if only by the $undef
  # net.
  YOSYS_SCRIPT "synth_xilinx -vpr -flatten $<SEMICOLON> opt_expr -undriven $<SEMICOLON> opt_clean"
)

add_subdirectory(tiles)
add_subdirectory(devices)
