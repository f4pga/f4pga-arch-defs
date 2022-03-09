set(CURR_DIR ${QL_DESIGNS_DIR}/lut4_8ffs)
add_file_target(FILE ${CURR_DIR}/lut4_8ffs.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME lut4_8ffs_test-umc22-no-adder
  TOP lut4_8ffs
  BOARD qlf_k4n8-qlf_k4n8_umc22_slow_board
  SOURCES ${CURR_DIR}/lut4_8ffs.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME lut4_8ffs_test-umc22-adder
  TOP lut4_8ffs
  BOARD qlf_k4n8-qlf_k4n8_umc22_slow_board
  SOURCES ${CURR_DIR}/lut4_8ffs.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_no_adder lut4_8ffs_test-umc22-no-adder_bit)
add_dependencies(all_qlf_k4n8_tests_adder    lut4_8ffs_test-umc22-adder_bit)
