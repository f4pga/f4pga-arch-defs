set(MULTIPLIER_8BIT ${QL_DESIGNS_DIR}/multiplier_8bit/multiplier_8bit.v)

add_fpga_target(
  NAME multiplier_8bit-gf12-no-adder
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES  ${MULTIPLIER_8BIT}
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME multiplier_8bit-gf12-adder
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES  ${MULTIPLIER_8BIT}
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k6n10_tests_no_adder multiplier_8bit-gf12-no-adder_route)
add_dependencies(all_qlf_k6n10_tests_adder    multiplier_8bit-gf12-adder_route)
