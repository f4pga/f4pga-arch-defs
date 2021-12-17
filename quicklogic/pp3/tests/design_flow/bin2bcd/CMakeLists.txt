set(DESIGN_DIR ${QL_DESIGNS_DIR}/bin2bcd)

add_fpga_target(
  NAME bin2bcd-ql-chandalar
  TOP bin2bcd
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/bin2bcd.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET

  ASSERT_BLOCK_TYPES_ARE_USED PB-BIDIR=20,PB-LOGIC<=17
  ASSERT_TIMING fmax>=12.0
)

add_jlink_output(
  PARENT bin2bcd-ql-chandalar
)

add_openocd_output(
  PARENT bin2bcd-ql-chandalar
)

add_dependencies(all_eos_s3_tests_bit   bin2bcd-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v bin2bcd-ql-chandalar_bit_v)
add_dependencies(all_eos_s3_tests_prog  bin2bcd-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog  bin2bcd-ql-chandalar_openocd)

add_dependencies(all_eos_s3_tests_regression bin2bcd-ql-chandalar_assert_usage)
add_dependencies(all_eos_s3_tests_regression bin2bcd-ql-chandalar_assert_timing)

