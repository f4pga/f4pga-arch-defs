set(XCU_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(PRJURAY_DIR ${symbiflow-arch-defs_SOURCE_DIR}/third_party/prjuray
  CACHE PATH "Path to prjuray library")
set(PRJURAY_DB_DIR
  ${symbiflow-arch-defs_SOURCE_DIR}/third_party/prjuray-db
  CACHE PATH "Path to prjuray database files")

#add_file_target(FILE ${YOSYS_DATADIR}/xilinx/cells_sim.v ABSOLUTE)
add_file_target(FILE ${symbiflow-arch-defs_SOURCE_DIR}/xc/xcu/techmap/cells_sim.v ABSOLUTE)
include(arch.cmake)

