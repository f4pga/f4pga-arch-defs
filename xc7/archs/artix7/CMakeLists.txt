set(ARCH artix7)
set(ROI_PART xc7a35tcpg236-1)
set(ROI_DIR ${PRJXRAY_DB_DIR}/${ARCH}/harness/basys3/swbut)

project_xray_prepare_database(
  PART ${ARCH}
)

add_subdirectory(tiles)

add_xc7_arch_define(
  # -flatten is used to ensure that the output eblif has only one module.
  # Some of symbiflow expects eblifs with only one module.
  #
  # opt -undriven makes sure all nets are driven, if only by the $undef
  # net.
  YOSYS_SCRIPT "synth_xilinx -vpr -flatten $<SEMICOLON> opt_expr -undriven $<SEMICOLON> opt_clean"
  DEVICES xc7a50t
)

add_subdirectory(devices)
