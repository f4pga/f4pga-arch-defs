set(TOP_120_13 ${QL_DESIGNS_DIR}/top_120_13/top_120_13.v)

add_fpga_target(
  NAME top_120_13-gf12-no-adder
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES ${TOP_120_13}
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME top_120_13-gf12-adder
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES ${TOP_120_13}
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k6n10_tests_no_adder top_120_13-gf12-no-adder_route)
add_dependencies(all_qlf_k6n10_tests_adder    top_120_13-gf12-adder_route)
