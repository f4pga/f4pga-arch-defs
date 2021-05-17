set(CURR_DIR ${QL_DESIGNS_DIR}/iir)
add_file_target(FILE ${CURR_DIR}/iir.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME iir_test-umc22-no-adder
  TOP iir
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${CURR_DIR}/iir.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
)

add_fpga_target(
  NAME iir_test-umc22-adder
  TOP iir
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${CURR_DIR}/iir.v
  EXPLICIT_ADD_FILE_TARGET
  )


add_dependencies(all_qlf_k4n8_tests_no_adder iir_test-umc22-no-adder_eblif)
add_dependencies(all_qlf_k4n8_tests_adder    iir_test-umc22-adder_eblif)
