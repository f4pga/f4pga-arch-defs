project_ray_prepare_database(
  PRJRAY_ARCH artix7
  PRJRAY_DIR ${PRJXRAY_DIR}
  PRJRAY_DB_DIR ${PRJXRAY_DB_DIR}
  PRJRAY_NAME prjxray
  PROTOTYPE_PART xc7a200tffg1156-1
  PARTS xc7a200tffg1156-1 xc7a200tsbg484-1
)

add_xc_arch_define(
  ARCH artix7_200t
  FAMILY xc7
  PRJRAY_DIR ${PRJXRAY_DIR}
  PRJRAY_DB_DIR ${PRJXRAY_DB_DIR}
  PRJRAY_NAME prjxray
  PRJRAY_ARCH artix7
  PROTOTYPE_PART xc7a200tffg1156-1
  YOSYS_SYNTH_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/yosys/synth.tcl
  YOSYS_CONV_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/yosys/conv.tcl
  YOSYS_UTILS_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/yosys/utils.tcl
)

add_subdirectory(tiles)
add_subdirectory(devices)
