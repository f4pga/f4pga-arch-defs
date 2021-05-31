set(COUNTER ${QL_DESIGNS_DIR}/counter/counter.v)
add_file_target(FILE ${COUNTER} SCANNER_TYPE verilog)

add_fpga_target(
  NAME counter-gf12-no-adder
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES ${COUNTER}
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
)

add_fpga_target(
  NAME counter-gf12-adder
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES ${COUNTER}
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k6n10_tests_no_adder counter-gf12-no-adder_route)
add_dependencies(all_qlf_k6n10_tests_adder    counter-gf12-adder_route)
