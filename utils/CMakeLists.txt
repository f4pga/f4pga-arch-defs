get_target_property_required(PYTEST env PYTEST)

add_custom_target(
  test_python
  DEPENDS conda_pytest
  COMMAND ${PYTEST} --doctest-modules -vv
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
