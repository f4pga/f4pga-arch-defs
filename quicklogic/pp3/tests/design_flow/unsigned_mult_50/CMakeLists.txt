set(DESIGN_DIR ${QL_DESIGNS_DIR}/unsigned_mult_50)

add_fpga_target(
  NAME unsigned_mult_50-ql-chandalar
  TOP top
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/unsigned_mult_50.v
  AUTO_ADD_FILE_TARGET

  ASSERT_USAGE PB-LOGIC<=908
)

# FIXME: The EOS-S3 fabric does not provide sufficient IO count
#add_dependencies(all_eos_s3_tests_bit        unsigned_mult_50-ql-chandalar_bit)
#add_dependencies(all_eos_s3_tests_regression unsigned_mult_50-ql-chandalar_assert_usage)

