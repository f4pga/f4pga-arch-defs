project_xray_prepare_database(
  PART zynq7
)

add_xc7_arch_define(
  ARCH zynq7
  YOSYS_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/xc7/yosys/synth.tcl
)

add_subdirectory(tiles)
add_subdirectory(devices)
