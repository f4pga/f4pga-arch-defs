set(DESIGN_DIR ${QL_DESIGNS_DIR}/top_120_13)

add_fpga_target(
  NAME top_120_13-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/top_120_13.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET

  ASSERT_USAGE PB-CLOCK=3,PB-GMUX=3,PB-LOGIC<=380
)


add_jlink_output(
  PARENT top_120_13-ql-chandalar
)

add_openocd_output(
  PARENT top_120_13-ql-chandalar
)

# FIXME: The EOS-S3 fabric does not provide sufficient IO count
#add_dependencies(all_eos_s3_tests_prog  top_120_13-ql-chandalar_jlink)
#add_dependencies(all_eos_s3_tests_prog  top_120_13-ql-chandalar_openocd)

#add_dependencies(all_eos_s3_tests_bit   top_120_13-ql-chandalar_bit)
#add_dependencies(all_eos_s3_tests_bit_v top_120_13-ql-chandalar_bit_v)

add_dependencies(top_120_13-ql-chandalar_analysis top_120_13-ql-chandalar_bit_v)

#add_dependencies(all_eos_s3_tests_regression top_120_13-ql-chandalar_assert_usage)
