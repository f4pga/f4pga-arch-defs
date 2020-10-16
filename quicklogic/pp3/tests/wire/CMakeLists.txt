add_file_target(FILE wire.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)
add_file_target(FILE jimbob4.pcf)

add_fpga_target(
  NAME wire-ql-chandalar
  BOARD chandalar
  SOURCES wire.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME wire-ql-jimbob4
  BOARD jimbob4
  SOURCES wire.v
  INPUT_IO_FILE jimbob4.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_ql_tests wire-ql-chandalar_route)
add_dependencies(all_ql_tests wire-ql-jimbob4_route)
