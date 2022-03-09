set(XC7_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(PRJXRAY_DIR ${symbiflow-arch-defs_SOURCE_DIR}/third_party/prjxray
  CACHE PATH "Path to prjxray library")

get_target_property_required(PRJXRAY_CONFIG env PRJXRAY_CONFIG)

if (NOT ${PRJXRAY_CONFIG} STREQUAL "PRJXRAY_CONFIG-NOTFOUND")
  execute_process(
    COMMAND
      bash ${PRJXRAY_CONFIG}
      OUTPUT_VARIABLE PRJXRAY_DB_DIR
  )
  string(STRIP "${PRJXRAY_DB_DIR}" PRJXRAY_DB_DIR)
else ()
  set(PRJXRAY_DB_DIR "PRJXRAY_DB_DIR-NOTFOUND")
endif ()

set(PRJXRAY_DB_DIR "${PRJXRAY_DB_DIR}"
  CACHE PATH "Path to prjxray database directory")

if (${PRJXRAY_DB_DIR} STREQUAL "PRJXRAY_DB_DIR-NOTFOUND")
  message(FATAL_ERROR "Could not find the project xray database directory! Please provide it with the PRJXRAY_DB_DIR variable")
endif ()

set(ARCH_IMPORT_TIMING ${symbiflow-arch-defs_SOURCE_DIR}/utils/update_arch_timings.py)
add_custom_target(
	arch_import_timing_deps
  DEPENDS ${ARCH_IMPORT_TIMING}
)

add_file_target(FILE "bels.json")

include(arch.cmake)

get_target_property_required(PYTEST env PYTEST)

add_custom_target(
  test_python_xc7
  COMMAND ${CMAKE_COMMAND} -E env
    PYTHONPATH=${symbiflow-arch-defs_SOURCE_DIR}/third_party/prjxray:${symbiflow-arch-defs_SOURCE_DIR}/utils:${symbiflow-arch-defs_SOURCE_DIR}/third_party/prjxray/third_party/fasm
     ${PYTEST} --doctest-modules -vv
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
add_dependencies(test_python test_python_xc7)
