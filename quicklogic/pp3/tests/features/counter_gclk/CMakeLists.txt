add_file_target(FILE counter.v SCANNER_TYPE verilog)
add_file_target(FILE quickfeather.pcf)

add_fpga_target(
  NAME regression-counter_gclk-ql-quickfeather
  BOARD quickfeather
  SOURCES counter.v
  INPUT_IO_FILE quickfeather.pcf
  EXPLICIT_ADD_FILE_TARGET
  ASSERT_BLOCK_TYPES_ARE_USED PB-BIDIR=4,PB-CLOCK=1,PB-GMUX=1,PB-LOGIC<=4
  ASSERT_TIMING fmax>55.0
)

add_dependencies(all_eos_s3_tests_regression regression-counter_gclk-ql-quickfeather_assert_usage)
