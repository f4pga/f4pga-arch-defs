add_file_target(FILE counter.v SCANNER_TYPE verilog)
add_file_target(FILE quickfeather.pcf)

add_fpga_target(
  NAME regression-counter-ql-quickfeather
  BOARD quickfeather
  SOURCES counter.v
  INPUT_IO_FILE quickfeather.pcf
  EXPLICIT_ADD_FILE_TARGET
  ASSERT_BLOCK_TYPES_ARE_USED PB-BIDIR=5,PB-CLOCK=0,PB-GMUX=0,PB-LOGIC<=4
  ASSERT_TIMING fmax>40.0
)

add_dependencies(all_eos_s3_tests_regression regression-counter-ql-quickfeather_assert_usage)
