add_file_target(FILE not.v SCANNER_TYPE verilog)
add_file_target(FILE not.pcf)

add_fpga_target(
  NAME not-ql-chandalar-top
  BOARD chandalar-top
  SOURCES not.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_ql_tests not-ql-chandalar-top_route)

