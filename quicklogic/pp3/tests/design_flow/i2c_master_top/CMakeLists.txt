set(DESIGN_DIR ${QL_DESIGNS_DIR}/i2c_master_top)

add_fpga_target(
  NAME i2c_master_top-ql-chandalar
  TOP i2c_master_top
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/i2c_master_defines.v
    ${DESIGN_DIR}/i2c_master_bit_ctrl.v
    ${DESIGN_DIR}/i2c_master_byte_ctrl.v
    ${DESIGN_DIR}/i2c_master_top.v
    ${DESIGN_DIR}/StateMachine.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET

  ASSERT_USAGE PB-CLOCK=2,PB-GMUX=2,PB-LOGIC<=160
)

add_jlink_output(
  PARENT i2c_master_top-ql-chandalar
)

add_openocd_output(
  PARENT i2c_master_top-ql-chandalar
)

add_dependencies(all_eos_s3_tests_bit   i2c_master_top-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v i2c_master_top-ql-chandalar_bit_v)
add_dependencies(all_eos_s3_tests_prog  i2c_master_top-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog  i2c_master_top-ql-chandalar_openocd)

add_dependencies(all_eos_s3_tests_regression i2c_master_top-ql-chandalar_assert_usage)
