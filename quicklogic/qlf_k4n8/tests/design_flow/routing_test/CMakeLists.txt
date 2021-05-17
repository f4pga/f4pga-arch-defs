set(CURR_DIR ${QL_DESIGNS_DIR}/routing_test)
add_file_target(FILE ${CURR_DIR}/routing_test.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME routing_test_test-umc22-no-adder
  TOP routing_test
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${CURR_DIR}/routing_test.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME routing_test_test-umc22-adder
  TOP routing_test
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${CURR_DIR}/routing_test.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_no_adder routing_test_test-umc22-no-adder_bit)
add_dependencies(all_qlf_k4n8_tests_adder    routing_test_test-umc22-adder_bit)
