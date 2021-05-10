set(ADDER_64 ${QL_DESIGNS_DIR}/adder_64/adder_64.v)

add_fpga_target(
  NAME adder_64-gf12-no-adder
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES ${ADDER_64}
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME adder_64-gf12-adder
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES ${ADDER_64}
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k6n10_tests_no_adder adder_64-gf12-no-adder_pack)
add_dependencies(all_qlf_k6n10_tests_adder    adder_64-gf12-adder_pack)
