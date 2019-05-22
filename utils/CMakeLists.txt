get_target_property_required(PYTEST env PYTEST)
get_target_property_required(SDF_TIMING_TARGET env SDF_TIMING_TARGET)

set(PYTHON_SDF_TIMING_DIR ${symbiflow-arch-defs_SOURCE_DIR}/third_party/python-sdf-timing)

add_custom_target(
  test_python_utils
  DEPENDS
    conda_pytest all_pip ${SDF_TIMING_TARGET}
  COMMAND ${PYTEST} --doctest-modules -vv
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

add_file_target(FILE "template.arch.xml" SCANNER_TYPE xml)

add_subdirectory(vlog)
add_dependencies(test_python test_python_utils)
