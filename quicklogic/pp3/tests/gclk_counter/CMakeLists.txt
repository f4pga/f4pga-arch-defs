add_file_target(FILE gclk_counter.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME gclk_counter-ql-chandalar
  BOARD chandalar
  SOURCES gclk_counter.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT gclk_counter-ql-chandalar
)

add_dependencies(all_ql_tests gclk_counter-ql-chandalar_bit)
add_dependencies(all_ql_tests gclk_counter-ql-chandalar_jlink)
