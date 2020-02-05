add_file_target(FILE wire.v SCANNER_TYPE verilog)
add_file_target(FILE wire.pcf)

add_fpga_target(
  NAME wire-ql-chandalar-top
  BOARD chandalar-top
  SOURCES wire.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_ql_tests wire-ql-chandalar-top_route)
