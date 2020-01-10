add_file_target(FILE oserdes_routing.v SCANNER_TYPE verilog)
add_file_target(FILE dummy.pcf)

add_fpga_target(
  NAME oserdes_routing
  BOARD basys3-bottom
  SOURCES oserdes_routing.v
  INPUT_IO_FILE dummy.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME oserdes_routing_vivado
  PARENT_NAME oserdes_routing
  )

add_dependencies(all_xc7_tests
  oserdes_routing
)

