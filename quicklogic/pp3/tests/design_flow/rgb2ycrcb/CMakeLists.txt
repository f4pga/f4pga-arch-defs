set(DESIGN_DIR ${QL_DESIGNS_DIR}/rgb2ycrcb)

add_fpga_target(
  NAME rgb2ycrcb-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/rgb2ycrcb.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET

  ASSERT_USAGE PB-CLOCK=1,PB-GMUX=1,PB-LOGIC<=496
  ASSERT_TIMING fmax>=10.0
)


add_jlink_output(
  PARENT rgb2ycrcb-ql-chandalar
)

add_openocd_output(
  PARENT rgb2ycrcb-ql-chandalar
)

# FIXME: The EOS-S3 fabric does not provide sufficient IO count
#add_dependencies(all_eos_s3_tests_prog  rgb2ycrcb-ql-chandalar_jlink)
#add_dependencies(all_eos_s3_tests_prog  rgb2ycrcb-ql-chandalar_openocd)

#add_dependencies(all_eos_s3_tests_bit   rgb2ycrcb-ql-chandalar_bit)
#add_dependencies(all_eos_s3_tests_bit_v rgb2ycrcb-ql-chandalar_bit_v)

add_dependencies(rgb2ycrcb-ql-chandalar_analysis rgb2ycrcb-ql-chandalar_bit_v)

#add_dependencies(all_eos_s3_tests_regression rgb2ycrcb-ql-chandalar_assert_usage)
#add_dependencies(all_eos_s3_tests_regression rgb2ycrcb-ql-chandalar_assert_timing)

