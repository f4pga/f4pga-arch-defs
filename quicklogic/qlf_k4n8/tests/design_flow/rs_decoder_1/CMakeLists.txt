set(CURR_DIR ${QL_DESIGNS_DIR}/rs_decoder_1)
add_file_target(FILE ${CURR_DIR}/rs_decoder_1.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME rs_decoder_1_test-umc22-no-adder
  TOP rs_decoder_1
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${CURR_DIR}/rs_decoder_1.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME rs_decoder_1_test-umc22-adder
  TOP rs_decoder_1
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${CURR_DIR}/rs_decoder_1.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_no_adder rs_decoder_1_test-umc22-no-adder_bit)
add_dependencies(all_qlf_k4n8_tests_adder    rs_decoder_1_test-umc22-adder_bit)
