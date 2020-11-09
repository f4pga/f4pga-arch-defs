add_file_target(FILE counter_16bit.v SCANNER_TYPE verilog)
add_file_target(FILE counter_16bit_tb.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME counter_16bit-ql-chandalar
  BOARD chandalar
  SOURCES counter_16bit.v
  TESTBENCH_SOURCES counter_16bit_tb.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
)

add_jlink_output(
  PARENT counter_16bit-ql-chandalar
)

add_openocd_output(
  PARENT counter_16bit-ql-chandalar
)

add_dependencies(all_ql_tests counter_16bit-ql-chandalar_bit)
add_dependencies(all_ql_tests counter_16bit-ql-chandalar_jlink)
add_dependencies(all_ql_tests counter_16bit-ql-chandalar_openocd)
add_dependencies(all_quick_tests counter_16bit-ql-chandalar_analysis)
add_dependencies(all_quick_tests testbench_counter_16bit_tb)

