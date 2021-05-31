set(BIN2BCD ${QL_DESIGNS_DIR}/bin2bcd/bin2bcd.v)

add_fpga_target(
  NAME bin2bcd-gf12-no-adder
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES ${BIN2BCD}
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME bin2bcd-gf12-adder
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES ${BIN2BCD}
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k6n10_tests_no_adder bin2bcd-gf12-no-adder_route)
add_dependencies(all_qlf_k6n10_tests_adder    bin2bcd-gf12-adder_route)

