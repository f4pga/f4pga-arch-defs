get_target_property_required(PYTEST env PYTEST)

add_custom_target(
  test_python_utils
  COMMAND ${PYTEST} --doctest-modules -vv
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

add_file_target(FILE "template.arch.xml" SCANNER_TYPE xml)

add_dependencies(test_python test_python_utils)

add_file_target(FILE "update_arch_tiles.py")
add_file_target(FILE "update_arch_timings.py")
