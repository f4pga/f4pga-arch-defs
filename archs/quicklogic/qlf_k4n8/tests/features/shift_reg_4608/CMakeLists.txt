set(CURR_DIR ${QL_DESIGNS_DIR}/shift_reg_4608)
add_file_target(FILE ${CURR_DIR}/shift_reg_4608.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME shift_reg_4608_test-umc22-adder
  TOP shift_reg_4608
  BOARD qlf_k4n8-qlf_k4n8_umc22_slow_board
  SOURCES ${CURR_DIR}/shift_reg_4608.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_adder    shift_reg_4608_test-umc22-adder_bit)
