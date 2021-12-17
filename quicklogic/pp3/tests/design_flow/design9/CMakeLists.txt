set(DESIGN_DIR ${QL_DESIGNS_DIR}/design9)

add_fpga_target(
  NAME design9-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/AL4S3B_FPGA_Top.v
    ${DESIGN_DIR}/AL4S3B_FPGA_IP.v
    ${DESIGN_DIR}/AL4S3B_FPGA_Registers.v
    ${DESIGN_DIR}/AL4S3B_FPGA_QL_Reserved.v
    ${DESIGN_DIR}/i2c_master_defines.v
    ${DESIGN_DIR}/I2C_Master_w_CmdQueue.v
    ${DESIGN_DIR}/i2c_master_top.v
    ${DESIGN_DIR}/i2c_master_byte_ctrl.v
    ${DESIGN_DIR}/i2c_master_bit_ctrl.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT design9-ql-chandalar
)

add_openocd_output(
  PARENT design9-ql-chandalar
)

add_dependencies(all_eos_s3_tests_bit  design9-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v design9-ql-chandalar_bit_v)
add_dependencies(all_eos_s3_tests_prog design9-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog design9-ql-chandalar_openocd)

