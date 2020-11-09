add_file_target(FILE ram.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME ram-ql-chandalar
  BOARD chandalar
  SOURCES ram.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT ram-ql-chandalar
)

add_openocd_output(
  PARENT ram-ql-chandalar
)

add_dependencies(all_quick_tests ram-ql-chandalar_bit)
add_dependencies(all_quick_tests ram-ql-chandalar_jlink)
add_dependencies(all_quick_tests ram-ql-chandalar_openocd)

add_dependencies(all_ql_tests ram-ql-chandalar_bit)
add_dependencies(all_ql_tests ram-ql-chandalar_jlink)
add_dependencies(all_ql_tests ram-ql-chandalar_openocd)

