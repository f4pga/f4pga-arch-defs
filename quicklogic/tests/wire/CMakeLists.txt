add_file_target(FILE wire.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)
add_file_target(FILE jimbo4.pcf)

add_fpga_target(
  NAME wire-ql-chandalar-top
  BOARD chandalar-top
  SOURCES wire.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME wire-ql-jimbo4
  BOARD jimbo4
  SOURCES wire.v
  INPUT_IO_FILE jimbo4.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_ql_tests wire-ql-chandalar-top_route)
