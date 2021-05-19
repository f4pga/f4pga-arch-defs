set(CURR_DIR ${QL_DESIGNS_DIR}/top_120_13)
add_file_target(FILE ${CURR_DIR}/top_120_13.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME top_120_13_test-umc22-no-adder
  TOP top_120_13
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${CURR_DIR}/top_120_13.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME top_120_13_test-umc22-adder
  TOP top_120_13
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${CURR_DIR}/top_120_13.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_no_adder top_120_13_test-umc22-no-adder_bit)
add_dependencies(all_qlf_k4n8_tests_adder    top_120_13_test-umc22-adder_bit)
