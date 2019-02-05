add_xc7_arch_define(
  ARCH zynq7
  ROI_PART xc7z010clg400-1
  ROI_DIR ${PRJXRAY_DB_DIR}/zynq7/harness/zybo/swbut
  YOSYS_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/xc7/yosys/synth.tcl
)

add_subdirectory(tiles)
add_subdirectory(devices)
