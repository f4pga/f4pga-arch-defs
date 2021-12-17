set(DESIGN_DIR ${QL_DESIGNS_DIR}/camif)

add_file_target(FILE ${DESIGN_DIR}/camif_new.v SCANNER_TYPE verilog)
add_file_target(FILE ${DESIGN_DIR}/af512x16_512x16.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME camif-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/camif_new.v
    ${DESIGN_DIR}/af512x16_512x16.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT camif-ql-chandalar
)

add_openocd_output(
  PARENT camif-ql-chandalar
)

add_dependencies(all_eos_s3_tests_bit  camif-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v camif-ql-chandalar_bit_v)
add_dependencies(all_eos_s3_tests_prog camif-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog camif-ql-chandalar_openocd)
add_dependencies(camif-ql-chandalar_analysis camif-ql-chandalar_bit_v)
