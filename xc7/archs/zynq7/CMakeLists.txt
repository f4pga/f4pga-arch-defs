project_xray_prepare_database(
  PRJXRAY_ARCH zynq7
  PROTOTYPE_PART xc7z010clg400-1
  PARTS xc7z010clg400-1
)

add_xc7_arch_define(
  ARCH zynq7
  PROTOTYPE_PART xc7z010clg400-1
  YOSYS_SYNTH_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/xc7/yosys/synth.tcl
  YOSYS_CONV_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/xc7/yosys/conv.tcl
)

add_subdirectory(tiles)
add_subdirectory(devices)
