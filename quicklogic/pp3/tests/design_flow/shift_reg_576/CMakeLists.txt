set(DESIGN_DIR ${QL_DESIGNS_DIR}/shift_reg_576)

add_fpga_target(
  NAME shift_reg_576-ql-chandalar
  TOP shift_reg_576
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/shift_reg_576.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET

  ASSERT_USAGE PB-CLOCK=2,PB-GMUX=2,PB-LOGIC=576
)


add_jlink_output(
  PARENT shift_reg_576-ql-chandalar
)

add_openocd_output(
  PARENT shift_reg_576-ql-chandalar
)

add_dependencies(all_eos_s3_tests_prog  shift_reg_576-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog  shift_reg_576-ql-chandalar_openocd)

add_dependencies(all_eos_s3_tests_bit   shift_reg_576-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v shift_reg_576-ql-chandalar_bit_v)

add_dependencies(shift_reg_576-ql-chandalar_analysis shift_reg_576-ql-chandalar_bit_v)

add_dependencies(all_eos_s3_tests_regression shift_reg_576-ql-chandalar_assert_usage)
