set(DESIGN_DIR ${QL_DESIGNS_DIR}/multiplier_8bit)

add_fpga_target(
  NAME multiplier_8bit-ql-chandalar
  TOP multiplier_8bit
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/multiplier_8bit.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET

  ASSERT_USAGE PB-LOGIC<=105
)


add_jlink_output(
  PARENT multiplier_8bit-ql-chandalar
)

add_openocd_output(
  PARENT multiplier_8bit-ql-chandalar
)

add_dependencies(all_eos_s3_tests_prog  multiplier_8bit-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog  multiplier_8bit-ql-chandalar_openocd)

add_dependencies(all_eos_s3_tests_bit   multiplier_8bit-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v multiplier_8bit-ql-chandalar_bit_v)

add_dependencies(multiplier_8bit-ql-chandalar_analysis multiplier_8bit-ql-chandalar_bit_v)

add_dependencies(all_eos_s3_tests_regression multiplier_8bit-ql-chandalar_assert_usage)

