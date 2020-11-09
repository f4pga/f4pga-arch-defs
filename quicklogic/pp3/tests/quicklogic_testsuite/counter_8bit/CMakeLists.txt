add_file_target(FILE counter_8bit.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME counter_8bit-ql-chandalar
  BOARD chandalar
  SOURCES counter_8bit.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT counter_8bit-ql-chandalar
)

add_openocd_output(
  PARENT counter_8bit-ql-chandalar
)

add_dependencies(all_ql_tests counter_8bit-ql-chandalar_bit)
add_dependencies(all_ql_tests counter_8bit-ql-chandalar_jlink)
add_dependencies(all_ql_tests counter_8bit-ql-chandalar_openocd)

