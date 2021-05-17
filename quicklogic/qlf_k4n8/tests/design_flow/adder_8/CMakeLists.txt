set(CURR_DIR ${QL_DESIGNS_DIR}/adder_8)
add_file_target(FILE ${CURR_DIR}/adder_8.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME adder_8_test1-umc22-no-adder
  TOP adder_8
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${CURR_DIR}/adder_8.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME adder_8_test1-umc22-adder
  TOP adder_8
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${CURR_DIR}/adder_8.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_no_adder adder_8_test1-umc22-no-adder_bit)
add_dependencies(all_qlf_k4n8_tests_adder    adder_8_test1-umc22-adder_bit)
