set(DESIGN_DIR ${QL_DESIGNS_DIR}/sha_top)

add_fpga_target(
  NAME sha_top-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/sha512.v
    ${DESIGN_DIR}/sha_top.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET
)


add_jlink_output(
  PARENT sha_top-ql-chandalar
)

add_openocd_output(
  PARENT sha_top-ql-chandalar
)

add_dependencies(all_eos_s3_tests_prog  sha_top-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog  sha_top-ql-chandalar_openocd)

add_dependencies(all_eos_s3_tests_bit   sha_top-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v sha_top-ql-chandalar_bit_v)

add_dependencies(sha_top-ql-chandalar_analysis sha_top-ql-chandalar_bit_v)

