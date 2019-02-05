add_xc7_arch_define(
  ARCH artix7
  ROI_PART xc7a35tcpg236-1
  ROI_DIR ${PRJXRAY_DB_DIR}/artix7/harness/basys3/swbut
  YOSYS_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/xc7/yosys/synth.tcl
)

add_subdirectory(tiles)
add_subdirectory(devices)
