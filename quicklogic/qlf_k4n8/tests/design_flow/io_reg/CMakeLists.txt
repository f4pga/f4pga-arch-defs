set(CURR_DIR ${QL_DESIGNS_DIR}/io_reg)
add_file_target(FILE ${CURR_DIR}/io_reg.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME io_reg_test-umc22-no-adder
  TOP io_reg
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${CURR_DIR}/io_reg.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME io_reg_test-umc22-adder
  TOP io_reg
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${CURR_DIR}/io_reg.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_no_adder io_reg_test-umc22-no-adder_bit)
add_dependencies(all_qlf_k4n8_tests_adder    io_reg_test-umc22-adder_bit)
