set(CURR_DIR ${QL_DESIGNS_DIR}/multi_enc_decx2x4)
add_file_target(FILE ${CURR_DIR}/multi_enc_decx2x4.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/topenc_decx2.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/encoder.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/decoder.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/adder_8.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME multi_enc_decx2x4_test-umc22-no-adder
  TOP multi_enc_decx2x4
  BOARD qlf_k4n8-qlf_k4n8_umc22_slow_board
  SOURCES
    ${CURR_DIR}/multi_enc_decx2x4.v
    ${CURR_DIR}/topenc_decx2.v
    ${CURR_DIR}/encoder.v
    ${CURR_DIR}/decoder.v
    ${CURR_DIR}/adder_8.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME multi_enc_decx2x4_test-umc22-adder
  TOP multi_enc_decx2x4
  BOARD qlf_k4n8-qlf_k4n8_umc22_slow_board
  SOURCES
    ${CURR_DIR}/multi_enc_decx2x4.v
    ${CURR_DIR}/topenc_decx2.v
    ${CURR_DIR}/encoder.v
    ${CURR_DIR}/decoder.v
    ${CURR_DIR}/adder_8.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_no_adder multi_enc_decx2x4_test-umc22-no-adder_bit)
add_dependencies(all_qlf_k4n8_tests_adder    multi_enc_decx2x4_test-umc22-adder_bit)
