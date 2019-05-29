set(XC7_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(PRJXRAY_DIR ${symbiflow-arch-defs_SOURCE_DIR}/third_party/prjxray
  CACHE PATH "Path to prjxray library")
set(PRJXRAY_DB_DIR
  ${symbiflow-arch-defs_SOURCE_DIR}/third_party/prjxray-db
  CACHE PATH "Path to prjxray database files")

get_target_property_required(PYTHON3 env PYTHON3)
get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

add_thirdparty_package(
  NAME sdf_timing
  BUILD_INSTALL_COMMAND "cd ${symbiflow-arch-defs_SOURCE_DIR}/third_party/python-sdf-timing && ${PYTHON3} setup.py develop"
  PROVIDES sdf_timing
  DEPENDS ${PYTHON3_TARGET}
)

get_target_property(SDF_TIMING_TARGET env SDF_TIMING_TARGET)
set(ARCH_IMPORT_TIMING ${symbiflow-arch-defs_SOURCE_DIR}/utils/update_arch_timings.py)
add_custom_target(
	arch_import_timing_deps
  DEPENDS ${ARCH_IMPORT_TIMING} ${SDF_TIMING_TARGET}
)

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
