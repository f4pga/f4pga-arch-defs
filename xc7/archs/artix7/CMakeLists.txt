project_xray_prepare_database(
  ARCH artix7
  PROTOTYPE_PART xc7a50tfgg484-1
  PARTS xc7a50tfgg484-1 xc7a200tffg1156-1
)

add_xc7_arch_define(
  ARCH artix7
  PROTOTYPE_PART xc7a50tfgg484-1
  YOSYS_SYNTH_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/xc7/yosys/synth.tcl
  YOSYS_CONV_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/xc7/yosys/conv.tcl
)

add_subdirectory(tiles)
add_subdirectory(devices)
