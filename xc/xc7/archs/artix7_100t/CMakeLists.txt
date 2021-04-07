project_ray_prepare_database(
  PRJRAY_ARCH artix7
  PRJRAY_DIR ${PRJXRAY_DIR}
  PRJRAY_DB_DIR ${PRJXRAY_DB_DIR}
  PROTOTYPE_PART xc7a100tfgg676-1
  PARTS xc7a100tfgg676-1 xc7a100tcsg324-1
)

set(ARCH artix7_100t)

set(YOSYS_SYNTH_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/yosys/synth.tcl)
set(YOSYS_CONV_SCRIPT  ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/yosys/conv.tcl)
set(YOSYS_UTILS_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/yosys/utils.tcl)

add_xc_arch_define(
  ARCH ${ARCH}
  FAMILY xc7
  PRJRAY_DIR ${PRJXRAY_DIR}
  PRJRAY_DB_DIR ${PRJXRAY_DB_DIR}
  PRJRAY_NAME prjxray
  PRJRAY_ARCH artix7
  PROTOTYPE_PART xc7a100tfgg676-1
  YOSYS_SYNTH_SCRIPT ${YOSYS_SYNTH_SCRIPT}
  YOSYS_CONV_SCRIPT  ${YOSYS_CONV_SCRIPT}
  YOSYS_UTILS_SCRIPT ${YOSYS_UTILS_SCRIPT}
)

add_subdirectory(tiles)
add_subdirectory(devices)

get_target_property_required(VPR_ARCH_ARGS ${ARCH} VPR_ARCH_ARGS)
define_xc_toolchain_target(
  ARCH ${ARCH}
  ROUTE_CHAN_WIDTH 500
  VPR_ARCH_ARGS ${VPR_ARCH_ARGS}
  CONV_SCRIPT  ${YOSYS_CONV_SCRIPT}
  SYNTH_SCRIPT ${YOSYS_SYNTH_SCRIPT}
  UTILS_SCRIPT ${YOSYS_UTILS_SCRIPT}
)

