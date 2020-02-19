add_file_target(FILE btn_xor.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar-top.pcf)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME btn_xor-ql-chandalar-top
  BOARD chandalar-top
  SOURCES btn_xor.v
  INPUT_IO_FILE chandalar-top.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT btn_xor-ql-chandalar-top
)

add_dependencies(all_ql_tests btn_xor-ql-chandalar-top_bit)
add_dependencies(all_ql_tests btn_xor-ql-chandalar-top_jlink)

add_fpga_target(
  NAME btn_xor-ql-chandalar
  BOARD chandalar
  SOURCES btn_xor.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT btn_xor-ql-chandalar
)

add_dependencies(all_ql_tests btn_xor-ql-chandalar_bit)
add_dependencies(all_ql_tests btn_xor-ql-chandalar_jlink)

