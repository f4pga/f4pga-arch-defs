get_target_property_required(PYTEST env PYTEST)
get_target_property(SDF_TIMING_TARGET env SDF_TIMING_TARGET)

add_custom_target(
  test_python_utils
  DEPENDS
    conda_pytest all_pip ${SDF_TIMING_TARGET}
  COMMAND ${PYTEST} --doctest-modules -vv
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

add_file_target(FILE "template.arch.xml" SCANNER_TYPE xml)

add_dependencies(test_python test_python_utils)

add_file_target(FILE "update_arch_tiles.py")
add_file_target(FILE "update_arch_timings.py")
