set(DESIGN_DIR ${QL_DESIGNS_DIR}/design10)

add_fpga_target(
  NAME design10-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/AL4S3B_FPGA_Top.v
    ${DESIGN_DIR}/AL4S3B_FPGA_Registers.v
    ${DESIGN_DIR}/AL4S3B_FPGA_QL_Reserved.v
    ${DESIGN_DIR}/AL4S3B_FPGA_IP.v
    ${DESIGN_DIR}/Dma_Ctrl.v
    ${DESIGN_DIR}/Fsm_Top.v
    ${DESIGN_DIR}/Serializer_Deserializer.v
    ${DESIGN_DIR}/Serializer_Deserializer_Test.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT design10-ql-chandalar
)

add_openocd_output(
  PARENT design10-ql-chandalar
)

add_dependencies(all_eos_s3_tests_bit  design10-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v design10-ql-chandalar_bit_v)
add_dependencies(all_eos_s3_tests_prog design10-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog design10-ql-chandalar_openocd)

