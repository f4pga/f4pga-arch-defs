set(DEPS "")
append_file_dependency(DEPS ${f4pga-arch-defs_SOURCE_DIR}/xilinx/common/primitives/bufgctrl/bufgctrl.pb_type.xml)
get_file_location(BUFGCTRL_PB_TYPE ${f4pga-arch-defs_SOURCE_DIR}/xilinx/common/primitives/bufgctrl/bufgctrl.pb_type.xml)

add_custom_command(
  OUTPUT bufgctrl.pb_type.xml
  COMMAND ${CMAKE_COMMAND} -E copy ${BUFGCTRL_PB_TYPE} ${CMAKE_CURRENT_BINARY_DIR}
  DEPENDS ${DEPS}
  )
add_file_target(FILE bufgctrl.pb_type.xml GENERATED)

set(DEPS "")
append_file_dependency(DEPS ${f4pga-arch-defs_SOURCE_DIR}/xilinx/common/primitives/bufgctrl/bufgctrl.model.xml)
get_file_location(BUFGCTRL_MODEL ${f4pga-arch-defs_SOURCE_DIR}/xilinx/common/primitives/bufgctrl/bufgctrl.model.xml)

add_custom_command(
  OUTPUT bufgctrl.model.xml
  COMMAND ${CMAKE_COMMAND} -E copy ${BUFGCTRL_MODEL} ${CMAKE_CURRENT_BINARY_DIR}
  DEPENDS ${DEPS}
  )
add_file_target(FILE bufgctrl.model.xml GENERATED)
