set(DESIGN_DIR ${QL_DESIGNS_DIR}/fifo_test)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME fifo_test-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/AL4S3B_FPGA_Top.v
    ${DESIGN_DIR}/AL4S3B_FPGA_IP.v
    ${DESIGN_DIR}/AL4S3B_FPGA_Registers.v
    ${DESIGN_DIR}/AL4S3B_FPGA_QL_Reserved.v
    ${DESIGN_DIR}/af512x32_512x32.v
    ${DESIGN_DIR}/f1024x16_1024x16.v
    ${DESIGN_DIR}/af512x16_512x16.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT fifo_test-ql-chandalar
)

add_openocd_output(
  PARENT fifo_test-ql-chandalar
)

add_dependencies(all_eos_s3_tests_bit  fifo_test-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v fifo_test-ql-chandalar_bit_v)
add_dependencies(all_eos_s3_tests_prog fifo_test-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog fifo_test-ql-chandalar_openocd)

