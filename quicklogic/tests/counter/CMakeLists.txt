add_file_target(FILE counter.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME counter-ql-chandalar-top
  BOARD chandalar-top
  SOURCES counter.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_ql_tests counter-ql-chandalar-top_route)

