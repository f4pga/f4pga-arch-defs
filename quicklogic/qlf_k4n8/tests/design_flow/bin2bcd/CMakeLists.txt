set(CURR_DIR ${QL_DESIGNS_DIR}/bin2bcd)
add_file_target(FILE ${CURR_DIR}/bin2bcd.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME bin2bcd_test-umc22-no-adder
  TOP bin2bcd
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${CURR_DIR}/bin2bcd.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME bin2bcd_test-umc22-adder
  TOP bin2bcd
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${CURR_DIR}/bin2bcd.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_no_adder bin2bcd_test-umc22-no-adder_bit)
add_dependencies(all_qlf_k4n8_tests_adder    bin2bcd_test-umc22-adder_bit)
