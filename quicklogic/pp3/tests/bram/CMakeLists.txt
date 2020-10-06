add_file_target(FILE bram.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME bram-ql-chandalar
  BOARD chandalar
  SOURCES bram.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT bram-ql-chandalar
)

add_openocd_output(
  PARENT bram-ql-chandalar
)

add_dependencies(all_ql_tests bram-ql-chandalar_bit)
add_dependencies(all_ql_tests bram-ql-chandalar_jlink)
add_dependencies(all_ql_tests bram-ql-chandalar_openocd)

