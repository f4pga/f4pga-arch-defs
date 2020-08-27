project_ray_prepare_database(
  PRJRAY_ARCH zynqusp
  PRJRAY_DIR ${PRJURAY_DIR}
  PRJRAY_DB_DIR ${PRJURAY_DB_DIR}
  PRJRAY_NAME prjuray
  PROTOTYPE_PART xczu3eg-sbva484-1-e
  PARTS xczu3eg-sbva484-1-e
)

add_xc_arch_define(
  ARCH zynqusp
  FAMILY xcu
  PRJRAY_DIR ${PRJURAY_DIR}
  PRJRAY_DB_DIR ${PRJURAY_DB_DIR}
  PRJRAY_NAME prjuray
  PROTOTYPE_PART xczu3eg-sbva484-1-e
  YOSYS_SYNTH_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/xc/xcu/yosys/synth.tcl
  YOSYS_CONV_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/xc/xcu/yosys/conv.tcl
)

add_subdirectory(tiles)
add_subdirectory(devices)
