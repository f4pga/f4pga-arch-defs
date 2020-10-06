set(XCU_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(PRJURAY_DIR ${symbiflow-arch-defs_SOURCE_DIR}/third_party/prjuray-tools
  CACHE PATH "Path to prjuray tools")
set(PRJURAY_DB_DIR
  ${symbiflow-arch-defs_SOURCE_DIR}/third_party/prjuray-db
  CACHE PATH "Path to prjuray database files")

set(ARCH_IMPORT_TIMING ${symbiflow-arch-defs_SOURCE_DIR}/utils/update_arch_timings.py)
#add_custom_target(
#	arch_import_timing_deps
#  DEPENDS ${ARCH_IMPORT_TIMING}
#)

add_file_target(FILE "bels.json")

add_subdirectory(primitives)
add_subdirectory(archs)
include(boards.cmake)
add_subdirectory(tests)

get_target_property_required(PYTEST env PYTEST)

add_custom_target(
  test_python_xcu
  DEPENDS
    conda_pytest all_pip
  COMMAND ${CMAKE_COMMAND} -E env
    PYTHONPATH=${symbiflow-arch-defs_SOURCE_DIR}/utils
     ${PYTEST} --doctest-modules -vv
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
add_dependencies(test_python test_python_xcu)
