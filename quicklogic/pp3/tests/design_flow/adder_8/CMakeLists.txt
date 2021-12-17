set(DESIGN_DIR ${QL_DESIGNS_DIR}/adder_8)

add_fpga_target(
  NAME adder_8-ql-chandalar
  TOP adder_8
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/adder_8.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET

  ASSERT_USAGE PB-BIDIR=26,PB-LOGIC<=8
  ASSERT_TIMING fmax>=13.5
)

add_jlink_output(
  PARENT adder_8-ql-chandalar
)

add_openocd_output(
  PARENT adder_8-ql-chandalar
)

add_dependencies(all_eos_s3_tests_bit   adder_8-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v adder_8-ql-chandalar_bit_v)
add_dependencies(all_eos_s3_tests_prog  adder_8-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog  adder_8-ql-chandalar_openocd)

add_dependencies(all_eos_s3_tests_regression adder_8-ql-chandalar_assert_usage)
add_dependencies(all_eos_s3_tests_regression adder_8-ql-chandalar_assert_timing)
