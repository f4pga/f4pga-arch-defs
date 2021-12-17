set(DESIGN_DIR ${QL_DESIGNS_DIR}/clock_test)

add_file_target(FILE ${DESIGN_DIR}/AL4S3B_FPGA_Top.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME clock_test-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/AL4S3B_FPGA_Top.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
)


add_jlink_output(
  PARENT clock_test-ql-chandalar
)

add_openocd_output(
  PARENT clock_test-ql-chandalar
)

add_dependencies(all_eos_s3_tests_prog  clock_test-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog  clock_test-ql-chandalar_openocd)

add_dependencies(all_eos_s3_tests_bit   clock_test-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v clock_test-ql-chandalar_bit_v)

add_dependencies(clock_test-ql-chandalar_analysis clock_test-ql-chandalar_bit_v)
