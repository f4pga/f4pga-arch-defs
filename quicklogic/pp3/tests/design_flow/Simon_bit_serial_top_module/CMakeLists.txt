set(DESIGN_DIR ${QL_DESIGNS_DIR}/Simon_bit_serial_top_module)

add_fpga_target(
  NAME Simon_bit_serial_top_module-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/Simon_bit_serial_datapath_FPGA.v
    ${DESIGN_DIR}/Simon_bit_serial_key_expansion_FPGA.v
    ${DESIGN_DIR}/Simon_bit_serial_top_module.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET
  
  ASSERT_USAGE PB-CLOCK=1,PB-GMUX=1,PB-LOGIC<=283
  ASSERT_TIMING fmax>=20.0
)


add_jlink_output(
  PARENT Simon_bit_serial_top_module-ql-chandalar
)

add_openocd_output(
  PARENT Simon_bit_serial_top_module-ql-chandalar
)

add_dependencies(all_eos_s3_tests_prog  Simon_bit_serial_top_module-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog  Simon_bit_serial_top_module-ql-chandalar_openocd)

add_dependencies(all_eos_s3_tests_bit   Simon_bit_serial_top_module-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v Simon_bit_serial_top_module-ql-chandalar_bit_v)

add_dependencies(Simon_bit_serial_top_module-ql-chandalar_analysis Simon_bit_serial_top_module-ql-chandalar_bit_v)

add_dependencies(all_eos_s3_tests_regression Simon_bit_serial_top_module-ql-chandalar_assert_usage)
add_dependencies(all_eos_s3_tests_regression Simon_bit_serial_top_module-ql-chandalar_assert_timing)
