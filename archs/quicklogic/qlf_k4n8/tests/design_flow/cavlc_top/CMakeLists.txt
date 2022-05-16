set(CURR_DIR ${QL_DESIGNS_DIR}/cavlc_top)
add_file_target(FILE ${CURR_DIR}/defines.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/cavlc_fsm.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/cavlc_len_gen.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/cavlc_read_levels.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/cavlc_read_run_befores.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/cavlc_read_total_coeffs.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/cavlc_read_total_zeros.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/cavlc_top.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME cavlc_top_test-umc22-no-adder
  TOP cavlc_top
  BOARD qlf_k4n8-qlf_k4n8_umc22_slow_board
  SOURCES
    ${CURR_DIR}/cavlc_fsm.v
    ${CURR_DIR}/cavlc_len_gen.v
    ${CURR_DIR}/cavlc_read_levels.v
    ${CURR_DIR}/cavlc_read_run_befores.v
    ${CURR_DIR}/cavlc_read_total_coeffs.v
    ${CURR_DIR}/cavlc_read_total_zeros.v
    ${CURR_DIR}/cavlc_top.v
    ${CURR_DIR}/defines.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME cavlc_top_test-umc22-adder
  TOP cavlc_top
  BOARD qlf_k4n8-qlf_k4n8_umc22_slow_board
  SOURCES
    ${CURR_DIR}/cavlc_fsm.v
    ${CURR_DIR}/cavlc_len_gen.v
    ${CURR_DIR}/cavlc_read_levels.v
    ${CURR_DIR}/cavlc_read_run_befores.v
    ${CURR_DIR}/cavlc_read_total_coeffs.v
    ${CURR_DIR}/cavlc_read_total_zeros.v
    ${CURR_DIR}/cavlc_top.v
    ${CURR_DIR}/defines.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_no_adder cavlc_top_test-umc22-no-adder_bit)
add_dependencies(all_qlf_k4n8_tests_adder    cavlc_top_test-umc22-adder_bit)
