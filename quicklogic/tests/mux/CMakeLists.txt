add_file_target(FILE mux2to1.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME mux2to1-ql-chandalar-top
  BOARD chandalar-top
  SOURCES mux2to1.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_ql_tests mux2to1-ql-chandalar-top_route)
