set(DESIGN_DIR ${QL_DESIGNS_DIR}/counter_al4s3b)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME counter_al4s3b-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/AL4S3B_FPGA_Top.v
    ${DESIGN_DIR}/AL4S3B_FPGA_IP.v
    ${DESIGN_DIR}/AL4S3B_FPGA_Registers.v
    ${DESIGN_DIR}/AL4S3B_FPGA_QL_Reserved.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT counter_al4s3b-ql-chandalar
)

add_openocd_output(
  PARENT counter_al4s3b-ql-chandalar
)

add_dependencies(all_eos_s3_tests_bit  counter_al4s3b-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v counter_al4s3b-ql-chandalar_bit_v)
add_dependencies(all_eos_s3_tests_prog counter_al4s3b-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog counter_al4s3b-ql-chandalar_openocd)
