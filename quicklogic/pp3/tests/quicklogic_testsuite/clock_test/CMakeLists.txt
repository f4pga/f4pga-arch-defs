add_file_target(FILE AL4S3B_FPGA_Top.v SCANNER TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME clock_test-ql-chandalar
  BOARD chandalar
  SOURCES AL4S3B_FPGA_Top.v 
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT clock_test-ql-chandalar
)

add_dependencies(all_ql_tests clock_test-ql-chandalar_bit)
add_dependencies(all_ql_tests clock_test-ql-chandalar_jlink)

