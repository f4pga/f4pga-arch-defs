set(ADDER_8 ${QL_DESIGNS_DIR}/adder_8/adder_8.v)

add_fpga_target(
  NAME adder_8-gf12-no-adder
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES ${ADDER_8}
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
)

add_fpga_target(
  NAME adder_8-gf12-adder
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES ${ADDER_8}
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k6n10_tests_no_adder adder_8-gf12-no-adder_route)
add_dependencies(all_qlf_k6n10_tests_adder    adder_8-gf12-adder_route)
