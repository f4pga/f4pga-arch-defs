add_file_target(FILE consts.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME consts-ql-chandalar
  BOARD chandalar
  SOURCES consts.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_ql_tests consts-ql-chandalar_route)

