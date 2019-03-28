get_target_property_required(PYTEST env PYTEST)

# TODO: figure out a better way instead of this hack. Maybe add_test
# just sucks or maybe we should write a wrapper test driver.
add_test(
  NAME pytest_in
  COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR} --target conda_pytest

  )

add_test(
  NAME python_tests
  COMMAND ${PYTEST} --doctest-modules
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  )
set_tests_properties(python_tests PROPERTIES DEPENDS pytest_in)
