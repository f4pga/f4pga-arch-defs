set(DESIGN_DIR ${QL_DESIGNS_DIR}/counter_16bit)

add_fpga_target(
  NAME counter_16bit-ql-chandalar
  TOP top
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/counter_16bit.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET

  ASSERT_BLOCK_TYPES_ARE_USED PB-CLOCK=1,PB-GMUX=1,PB-LOGIC<=18
  ASSERT_TIMING fmax>=20.0
)

add_jlink_output(
  PARENT counter_16bit-ql-chandalar
)

add_openocd_output(
  PARENT counter_16bit-ql-chandalar
)

add_dependencies(all_eos_s3_tests_bit   counter_16bit-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v counter_16bit-ql-chandalar_bit_v)
add_dependencies(all_eos_s3_tests_prog  counter_16bit-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog  counter_16bit-ql-chandalar_openocd)

add_dependencies(all_eos_s3_tests_regression counter_16bit-ql-chandalar_assert_usage)
add_dependencies(all_eos_s3_tests_regression counter_16bit-ql-chandalar_assert_timing)
