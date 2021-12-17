set(DESIGN_DIR ${QL_DESIGNS_DIR}/jpeg_qnr)

add_fpga_target(
  NAME jpeg_qnr-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/div_su.v
    ${DESIGN_DIR}/div_uu.v
    ${DESIGN_DIR}/jpeg_qnr.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET

  ASSERT_USAGE PB-CLOCK=1,PB-GMUX=1,PB-LOGIC<=465
  ASSERT_TIMING fmax>=18.0
)

add_jlink_output(
  PARENT jpeg_qnr-ql-chandalar
)

add_openocd_output(
  PARENT jpeg_qnr-ql-chandalar
)

# FIXME: The EOS-S3 fabric does not provide sufficient IO count
#add_dependencies(all_eos_s3_tests_prog  jpeg_qnr-ql-chandalar_jlink)
#add_dependencies(all_eos_s3_tests_prog  jpeg_qnr-ql-chandalar_openocd)

#add_dependencies(all_eos_s3_tests_bit   jpeg_qnr-ql-chandalar_bit)
#add_dependencies(all_eos_s3_tests_bit_v jpeg_qnr-ql-chandalar_bit_v)

#add_dependencies(all_eos_s3_tests_regression jpeg_qnr-ql-chandalar_assert_usage)
#add_dependencies(all_eos_s3_tests_regression jpeg_qnr-ql-chandalar_assert_timing)

add_dependencies(jpeg_qnr-ql-chandalar_analysis jpeg_qnr-ql-chandalar_bit_v)

