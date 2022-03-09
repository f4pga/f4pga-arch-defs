project_ray_prepare_database(
  PRJRAY_ARCH zynq7
  PRJRAY_DIR ${PRJXRAY_DIR}
  PRJRAY_DB_DIR ${PRJXRAY_DB_DIR}
  PROTOTYPE_PART xc7z010clg400-1
  PARTS xc7z010clg400-1
)

set(ARCH zynq7)

set(YOSYS_SYNTH_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/yosys/synth.tcl)
set(YOSYS_CONV_SCRIPT  ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/yosys/conv.tcl)
set(YOSYS_UTILS_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/yosys/utils.tcl)

add_xc_arch_define(
  ARCH ${ARCH}
  FAMILY xc7
  PRJRAY_DIR ${PRJXRAY_DIR}
  PRJRAY_DB_DIR ${PRJXRAY_DB_DIR}
  PRJRAY_NAME prjxray
  PROTOTYPE_PART xc7z010clg400-1
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

