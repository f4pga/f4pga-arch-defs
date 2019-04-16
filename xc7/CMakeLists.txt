set(XC7_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(PRJXRAY_DIR ${symbiflow-arch-defs_SOURCE_DIR}/third_party/prjxray)
set(PRJXRAY_DB_DIR
  ${symbiflow-arch-defs_SOURCE_DIR}/third_party/prjxray-db
  CACHE PATH "Path to prjxray database files")

include(arch.cmake)

get_target_property_required(PYTEST env PYTEST)

add_custom_target(
  test_python_xc7
  DEPENDS
    conda_pytest all_pip
  COMMAND ${CMAKE_COMMAND} -E env
    PYTHONPATH=${symbiflow-arch-defs_SOURCE_DIR}/third_party/prjxray:${symbiflow-arch-defs_SOURCE_DIR}/utils:${symbiflow-arch-defs_SOURCE_DIR}/third_party/prjxray/third_party/fasm
     ${PYTEST} --doctest-modules -vv
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
add_dependencies(test_python test_python_xc7)
