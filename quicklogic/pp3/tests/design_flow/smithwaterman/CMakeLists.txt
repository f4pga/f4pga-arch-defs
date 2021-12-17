set(DESIGN_DIR ${QL_DESIGNS_DIR}/smithwaterman)

add_fpga_target(
  NAME smithwaterman-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/smithwaterman.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET
)


add_jlink_output(
  PARENT smithwaterman-ql-chandalar
)

add_openocd_output(
  PARENT smithwaterman-ql-chandalar
)

add_dependencies(all_eos_s3_tests_prog  smithwaterman-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog  smithwaterman-ql-chandalar_openocd)

add_dependencies(all_eos_s3_tests_bit   smithwaterman-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v smithwaterman-ql-chandalar_bit_v)

add_dependencies(smithwaterman-ql-chandalar_analysis smithwaterman-ql-chandalar_bit_v)

