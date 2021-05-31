set(UNSIGNED_MULT_80 ${QL_DESIGNS_DIR}/unsigned_mult_80/unsigned_mult_80.v)

add_file_target(FILE ${UNSIGNED_MULT_80} SCANNER_TYPE verilog)

add_fpga_target(
  NAME unsigned_mult_80-gf12-no-adder
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES ${UNSIGNED_MULT_80}
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME unsigned_mult_80-gf12-adder
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES ${UNSIGNED_MULT_80}
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k6n10_tests_no_adder unsigned_mult_80-gf12-no-adder_route)
add_dependencies(all_qlf_k6n10_tests_adder    unsigned_mult_80-gf12-adder_route)
