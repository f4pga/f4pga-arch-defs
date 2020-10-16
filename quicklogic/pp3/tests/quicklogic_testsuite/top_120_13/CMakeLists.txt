add_file_target(FILE top_120_13.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME top-120-13-ql-chandalar
  BOARD chandalar
  SOURCES top_120_13.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT top-120-13-ql-chandalar
)

add_dependencies(all_ql_tests top-120-13-ql-chandalar_bit)
add_dependencies(all_ql_tests top-120-13-ql-chandalar_jlink)

