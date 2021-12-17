set(DESIGN_DIR ${QL_DESIGNS_DIR}/clock_tree_design)

add_fpga_target(
  NAME clock_tree_design-ql-chandalar
  TOP clock_tree_design_pp3
  BOARD chandalar
  SOURCES
    clock_tree_design_pp3.v
    ${DESIGN_DIR}/clock_tree_design.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET

  ASSERT_USAGE PB-CLOCK=5,PB-GMUX=5,PB-LOGIC<=133
)

add_jlink_output(
  PARENT clock_tree_design-ql-chandalar
)

add_openocd_output(
  PARENT clock_tree_design-ql-chandalar
)

add_dependencies(all_eos_s3_tests_bit   clock_tree_design-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v clock_tree_design-ql-chandalar_bit_v)
add_dependencies(all_eos_s3_tests_prog  clock_tree_design-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog  clock_tree_design-ql-chandalar_openocd)

add_dependencies(all_eos_s3_tests_regression clock_tree_design-ql-chandalar_assert_usage)

