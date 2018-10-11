get_target_property_required(PYTEST env PYTEST)

add_test(
  NAME python_tests
  COMMAND ${PYTEST}
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  )

add_subdirectory(vlog)
