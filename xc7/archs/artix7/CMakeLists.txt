project_xray_prepare_database(
  ARCH artix7
  PART xc7a35tcpg236-1
)

add_xc7_arch_define(
  ARCH artix7
  PART xc7a35tcpg236-1
  YOSYS_SYNTH_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/xc7/yosys/synth.tcl
  YOSYS_CONV_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/xc7/yosys/conv.tcl
)

add_subdirectory(tiles)
add_subdirectory(devices)
