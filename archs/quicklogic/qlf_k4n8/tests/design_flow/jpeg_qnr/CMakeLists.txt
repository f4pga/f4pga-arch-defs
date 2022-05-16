set(CURR_DIR ${QL_DESIGNS_DIR}/jpeg_qnr)
add_file_target(FILE ${CURR_DIR}/jpeg_qnr.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/div_su.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/div_uu.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME jpeg_qnr_test-umc22-no-adder
  TOP jpeg_qnr
  BOARD qlf_k4n8-qlf_k4n8_umc22_slow_board
  SOURCES ${CURR_DIR}/jpeg_qnr.v ${CURR_DIR}/div_su.v ${CURR_DIR}/div_uu.v 
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME jpeg_qnr_test-umc22-adder
  TOP jpeg_qnr
  BOARD qlf_k4n8-qlf_k4n8_umc22_slow_board
  SOURCES ${CURR_DIR}/jpeg_qnr.v ${CURR_DIR}/div_su.v ${CURR_DIR}/div_uu.v 
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_no_adder jpeg_qnr_test-umc22-no-adder_bit)
add_dependencies(all_qlf_k4n8_tests_adder    jpeg_qnr_test-umc22-adder_bit)
