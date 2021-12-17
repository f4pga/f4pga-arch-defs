set(DESIGN_DIR ${QL_DESIGNS_DIR}/sha256)

add_fpga_target(
  NAME sha256-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/sha256.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET
)


add_jlink_output(
  PARENT sha256-ql-chandalar
)

add_openocd_output(
  PARENT sha256-ql-chandalar
)

add_dependencies(all_eos_s3_tests_prog  sha256-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog  sha256-ql-chandalar_openocd)

add_dependencies(all_eos_s3_tests_bit   sha256-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v sha256-ql-chandalar_bit_v)

add_dependencies(sha256-ql-chandalar_analysis sha256-ql-chandalar_bit_v)

