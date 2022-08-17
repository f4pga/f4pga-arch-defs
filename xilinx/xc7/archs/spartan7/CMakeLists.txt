project_ray_prepare_database(
  PRJRAY_ARCH spartan7
  PRJRAY_DIR ${PRJXRAY_DIR}
  PRJRAY_DB_DIR ${PRJXRAY_DB_DIR}
  PROTOTYPE_PART xc7s50fgga484-1
  PARTS xc7s50fgga484-1
)

set(ARCH spartan7)

add_xc_arch_define(
  ARCH ${ARCH}
  FAMILY xc7
  PRJRAY_DIR ${PRJXRAY_DIR}
  PRJRAY_DB_DIR ${PRJXRAY_DB_DIR}
  PRJRAY_NAME prjxray
  PROTOTYPE_PART xc7s50fgga484-1
)

add_subdirectory(tiles)
add_subdirectory(devices)

get_target_property_required(VPR_ARCH_ARGS ${ARCH} VPR_ARCH_ARGS)
define_xc_toolchain_target(
  ARCH ${ARCH}
  ROUTE_CHAN_WIDTH 500
  VPR_ARCH_ARGS ${VPR_ARCH_ARGS}
)

