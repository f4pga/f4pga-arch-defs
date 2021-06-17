set(CURR_DIR ${QL_DESIGNS_DIR}/unsigned_mult_80)
add_file_target(FILE ${CURR_DIR}/unsigned_mult_80.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME unsigned_mult_80_test-umc22-no-adder
  TOP unsigned_mult_80
  BOARD qlf_k4n8-qlf_k4n8_umc22_slow_board
  SOURCES ${CURR_DIR}/unsigned_mult_80.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME unsigned_mult_80_test-umc22-adder
  TOP unsigned_mult_80
  BOARD qlf_k4n8-qlf_k4n8_umc22_slow_board
  SOURCES ${CURR_DIR}/unsigned_mult_80.v
  EXPLICIT_ADD_FILE_TARGET
  )

# The no_adder version does not fit into the 24x24 device (requires 590 clb, have 576)
#add_dependencies(all_qlf_k4n8_tests_no_adder unsigned_mult_80_test-umc22-no-adder_bit)

add_dependencies(all_qlf_k4n8_tests_adder    unsigned_mult_80_test-umc22-adder_bit)
