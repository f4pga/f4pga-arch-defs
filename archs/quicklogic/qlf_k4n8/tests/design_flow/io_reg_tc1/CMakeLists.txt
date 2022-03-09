set(CURR_DIR ${QL_DESIGNS_DIR}/io_reg_tc1)
add_file_target(FILE ${CURR_DIR}/io_reg_tc1.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/demux.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/mux.v SCANNER_TYPE verilog)


add_fpga_target(
  NAME io_reg_tc1_test-umc22-no-adder
  TOP io_reg_tc1
  BOARD qlf_k4n8-qlf_k4n8_umc22_slow_board
  SOURCES ${CURR_DIR}/io_reg_tc1.v ${CURR_DIR}/demux.v ${CURR_DIR}/mux.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME io_reg_tc1_test-umc22-adder
  TOP io_reg_tc1
  BOARD qlf_k4n8-qlf_k4n8_umc22_slow_board
  SOURCES ${CURR_DIR}/io_reg_tc1.v ${CURR_DIR}/demux.v ${CURR_DIR}/mux.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_no_adder io_reg_tc1_test-umc22-no-adder_bit)
add_dependencies(all_qlf_k4n8_tests_adder    io_reg_tc1_test-umc22-adder_bit)
