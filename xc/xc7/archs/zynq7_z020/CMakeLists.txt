project_ray_prepare_database(
  PRJRAY_ARCH zynq7
  PRJRAY_DIR ${PRJXRAY_DIR}
  PRJRAY_DB_DIR ${PRJXRAY_DB_DIR}
  PRJRAY_NAME prjxray
  PROTOTYPE_PART xc7z020clg484-1  
  PARTS xc7z020clg484-1
)

add_xc_arch_define(
  ARCH zynq7_z020
  FAMILY xc7
  PRJRAY_DIR ${PRJXRAY_DIR}
  PRJRAY_DB_DIR ${PRJXRAY_DB_DIR}
  PRJRAY_NAME prjxray
  PRJRAY_ARCH zynq7
  PROTOTYPE_PART xc7z020clg484-1
  YOSYS_SYNTH_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/yosys/synth.tcl
  YOSYS_CONV_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/yosys/conv.tcl
  YOSYS_UTILS_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/yosys/utils.tcl
)

add_subdirectory(tiles)
add_subdirectory(devices)
