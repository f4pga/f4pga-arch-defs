add_file_target(FILE mult.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME mult-ql-chandalar
  BOARD chandalar
  SOURCES mult.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT mult-ql-chandalar
)

add_openocd_output(
  PARENT mult-ql-chandalar
)

add_dependencies(all_quick_tests mult-ql-chandalar_bit)
add_dependencies(all_quick_tests mult-ql-chandalar_jlink)
add_dependencies(all_quick_tests mult-ql-chandalar_openocd)

add_dependencies(all_ql_tests mult-ql-chandalar_bit)
add_dependencies(all_ql_tests mult-ql-chandalar_jlink)
add_dependencies(all_ql_tests mult-ql-chandalar_openocd)

