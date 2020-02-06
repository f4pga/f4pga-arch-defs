add_file_target(FILE consts.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME consts-ql-chandalar-top
  BOARD chandalar-top
  SOURCES consts.v
  EXPLICIT_ADD_FILE_TARGET
  )
add_dependencies(all_ql_tests consts-ql-chandalar-top_route)

