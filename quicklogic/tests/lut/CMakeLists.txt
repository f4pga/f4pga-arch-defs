add_file_target(FILE lut1.v SCANNER_TYPE verilog)
add_file_target(FILE lut2.v SCANNER_TYPE verilog)
add_file_target(FILE lut3.v SCANNER_TYPE verilog)
add_file_target(FILE lut4.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME lut1-ql-chandalar-top
  BOARD chandalar-top
  SOURCES lut1.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME lut2-ql-chandalar-top
  BOARD chandalar-top
  SOURCES lut2.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME lut3-ql-chandalar-top
  BOARD chandalar-top
  SOURCES lut3.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME lut4-ql-chandalar-top
  BOARD chandalar-top
  SOURCES lut4.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_ql_tests lut1-ql-chandalar-top_route)
add_dependencies(all_ql_tests lut2-ql-chandalar-top_route)
add_dependencies(all_ql_tests lut3-ql-chandalar-top_route)
add_dependencies(all_ql_tests lut4-ql-chandalar-top_route)

