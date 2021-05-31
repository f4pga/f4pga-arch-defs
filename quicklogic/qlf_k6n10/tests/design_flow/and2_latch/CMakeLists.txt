set(AND2_LATCH ${QL_DESIGNS_DIR}/and2_latch/and2_latch.v)

add_fpga_target(
  NAME and2_latch-gf12-no-adder
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES ${AND2_LATCH}
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME and2_latch-gf12-adder
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES ${AND2_LATCH}
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k6n10_tests_no_adder and2_latch-gf12-no-adder_route)
add_dependencies(all_qlf_k6n10_tests_adder    and2_latch-gf12-adder_route)
