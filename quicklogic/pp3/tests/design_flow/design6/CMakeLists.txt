set(DESIGN_DIR ${QL_DESIGNS_DIR}/design6)

add_fpga_target(
  NAME design6-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/AL4S3B_FPGA_Top.v
    ${DESIGN_DIR}/AL4S3B_FPGA_IP.v
    ${DESIGN_DIR}/AL4S3B_FPGA_QL_Reserved.v
    ${DESIGN_DIR}/AL4S3B_FPGA_Registers.v
    ${DESIGN_DIR}/duty_cycle_count.v
    ${DESIGN_DIR}/freq_counter.v
    ${DESIGN_DIR}/pwm_counter.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT design6-ql-chandalar
)

add_openocd_output(
  PARENT design6-ql-chandalar
)

add_dependencies(all_eos_s3_tests_bit  design6-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v design6-ql-chandalar_bit_v)
add_dependencies(all_eos_s3_tests_prog design6-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog design6-ql-chandalar_openocd)

