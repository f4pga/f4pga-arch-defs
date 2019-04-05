set(XC7_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(PRJXRAY_DIR ${symbiflow-arch-defs_SOURCE_DIR}/third_party/prjxray)
set(PRJXRAY_DB_DIR
  ${symbiflow-arch-defs_SOURCE_DIR}/third_party/prjxray-db
  CACHE PATH "Path to prjxray database files")

include(arch.cmake)
