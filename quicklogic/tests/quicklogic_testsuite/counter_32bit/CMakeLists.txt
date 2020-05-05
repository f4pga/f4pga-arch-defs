add_file_target(FILE counter_32bit.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME counter_32bit-ql-chandalar
  BOARD chandalar
  SOURCES counter_32bit.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT counter_32bit-ql-chandalar
)

add_dependencies(all_ql_tests counter_32bit-ql-chandalar_bit)
add_dependencies(all_ql_tests counter_32bit-ql-chandalar_jlink)

