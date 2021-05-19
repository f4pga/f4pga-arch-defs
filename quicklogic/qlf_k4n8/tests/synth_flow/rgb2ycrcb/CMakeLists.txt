set(CURR_DIR ${QL_DESIGNS_DIR}/rgb2ycrcb)
add_file_target(FILE ${CURR_DIR}/rgb2ycrcb.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME rgb2ycrcb_test-umc22-no-adder
  TOP rgb2ycrcb
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${CURR_DIR}/rgb2ycrcb.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
)

add_fpga_target(
  NAME rgb2ycrcb_test-umc22-adder
  TOP rgb2ycrcb
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${CURR_DIR}/rgb2ycrcb.v
  EXPLICIT_ADD_FILE_TARGET
  )


add_dependencies(all_qlf_k4n8_tests_no_adder rgb2ycrcb_test-umc22-no-adder_eblif)
add_dependencies(all_qlf_k4n8_tests_adder    rgb2ycrcb_test-umc22-adder_eblif)
