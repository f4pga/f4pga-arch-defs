set(CURR_DIR ${QL_DESIGNS_DIR}/des_perf)
add_file_target(FILE ${CURR_DIR}/des_perf.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME des_perf_test-umc22-no-adder
  TOP des_perf
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${CURR_DIR}/des_perf.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
)

add_fpga_target(
  NAME des_perf_test-umc22-adder
  TOP des_perf
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${CURR_DIR}/des_perf.v
  EXPLICIT_ADD_FILE_TARGET
  )


add_dependencies(all_qlf_k4n8_tests_no_adder des_perf_test-umc22-no-adder_eblif)
add_dependencies(all_qlf_k4n8_tests_adder    des_perf_test-umc22-adder_eblif)
