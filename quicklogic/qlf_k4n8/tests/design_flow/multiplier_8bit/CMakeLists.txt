set(CURR_DIR ${QL_DESIGNS_DIR}/multiplier_8bit)
add_file_target(FILE ${CURR_DIR}/multiplier_8bit.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME multiplier_8bit_test-umc22-no-adder
  TOP multiplier_8bit
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${CURR_DIR}/multiplier_8bit.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME multiplier_8bit_test-umc22-adder
  TOP multiplier_8bit
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${CURR_DIR}/multiplier_8bit.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_no_adder multiplier_8bit_test-umc22-no-adder_bit)
add_dependencies(all_qlf_k4n8_tests_adder    multiplier_8bit_test-umc22-adder_bit)
