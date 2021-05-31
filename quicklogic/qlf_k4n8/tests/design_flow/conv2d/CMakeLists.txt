set(CURR_DIR ${QL_DESIGNS_DIR}/conv2d)
add_file_target(FILE ${CURR_DIR}/conv2d.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/control.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/ksa.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/ksa1.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/tfl.v SCANNER_TYPE verilog)
add_file_target(FILE conv2d.sdc SCANNER_TYPE)

add_fpga_target(
  NAME conv2d_test-umc22-no-adder
  TOP top
  BOARD qlf_k4n8-qlf_k4n8_umc22_slow_board
  SOURCES ${CURR_DIR}/conv2d.v ${CURR_DIR}/control.v ${CURR_DIR}/ksa.v ${CURR_DIR}/ksa1.v ${CURR_DIR}/tfl.v
  EXPLICIT_ADD_FILE_TARGET
  INPUT_SDC_FILE conv2d.sdc
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME conv2d_test-umc22-adder
  TOP top
  BOARD qlf_k4n8-qlf_k4n8_umc22_slow_board
  SOURCES ${CURR_DIR}/conv2d.v ${CURR_DIR}/control.v ${CURR_DIR}/ksa.v ${CURR_DIR}/ksa1.v ${CURR_DIR}/tfl.v
  EXPLICIT_ADD_FILE_TARGET
  INPUT_SDC_FILE conv2d.sdc
  )

add_dependencies(all_qlf_k4n8_tests_no_adder conv2d_test-umc22-no-adder_bit)
add_dependencies(all_qlf_k4n8_tests_adder    conv2d_test-umc22-adder_bit)
