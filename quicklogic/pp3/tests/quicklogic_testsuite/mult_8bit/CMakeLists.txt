add_file_target(FILE mult_8bit.v SCANNER_TYPE verilog)
add_file_target(FILE mult_8bit_tb.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME mult_8bit-ql-chandalar
  BOARD chandalar
  SOURCES mult_8bit.v
  TESTBENCH_SOURCES mult_8bit_tb.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT mult_8bit-ql-chandalar
)

add_dependencies(all_ql_tests mult_8bit-ql-chandalar_bit)
add_dependencies(all_ql_tests mult_8bit-ql-chandalar_jlink)
add_dependencies(all_quick_tests mult_8bit-ql-chandalar_analysis)
add_dependencies(mult_8bit-ql-chandalar_analysis mult_8bit-ql-chandalar_bit_v)
add_dependencies(all_quick_tests testbench_mult_8bit_tb)
