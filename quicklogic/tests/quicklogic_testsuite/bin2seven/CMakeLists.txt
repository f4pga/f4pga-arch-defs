add_file_target(FILE bin2seven.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME bin2seven-ql-chandalar
  BOARD chandalar
  SOURCES bin2seven.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT bin2seven-ql-chandalar
)

add_dependencies(all_ql_tests bin2seven-ql-chandalar_bit)
add_dependencies(all_ql_tests bin2seven-ql-chandalar_jlink)

