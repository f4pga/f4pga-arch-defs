set(DESIGN_DIR ${QL_DESIGNS_DIR}/rs_decoder_1)

add_fpga_target(
  NAME rs_decoder_1-ql-chandalar
  TOP rs_decoder_1
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/rs_decoder_1.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET

  ASSERT_USAGE PB-CLOCK=1,PB-GMUX=1,PB-LOGIC<=27
  ASSERT_TIMING fmax>=25.0
)


add_jlink_output(
  PARENT rs_decoder_1-ql-chandalar
)

add_openocd_output(
  PARENT rs_decoder_1-ql-chandalar
)

add_dependencies(all_eos_s3_tests_prog  rs_decoder_1-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog  rs_decoder_1-ql-chandalar_openocd)

add_dependencies(all_eos_s3_tests_bit   rs_decoder_1-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v rs_decoder_1-ql-chandalar_bit_v)

add_dependencies(rs_decoder_1-ql-chandalar_analysis rs_decoder_1-ql-chandalar_bit_v)

add_dependencies(all_eos_s3_tests_regression rs_decoder_1-ql-chandalar_assert_usage)
add_dependencies(all_eos_s3_tests_regression rs_decoder_1-ql-chandalar_assert_timing)

