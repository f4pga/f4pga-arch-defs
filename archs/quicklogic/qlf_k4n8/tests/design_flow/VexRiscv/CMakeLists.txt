set(CURR_DIR ${QL_DESIGNS_DIR}/VexRiscv)
add_file_target(FILE ${CURR_DIR}/VexRiscv.v SCANNER_TYPE verilog)
add_file_target(FILE VexRiscv.sdc SCANNER_TYPE)

add_fpga_target(
  NAME VexRiscv_test-umc22-no-adder
  TOP VexRiscv
  BOARD qlf_k4n8-qlf_k4n8_umc22_slow_board
  SOURCES ${CURR_DIR}/VexRiscv.v
  EXPLICIT_ADD_FILE_TARGET
  INPUT_SDC_FILE VexRiscv.sdc
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME VexRiscv_test-umc22-adder
  TOP VexRiscv
  BOARD qlf_k4n8-qlf_k4n8_umc22_slow_board
  SOURCES ${CURR_DIR}/VexRiscv.v
  INPUT_SDC_FILE VexRiscv.sdc
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_no_adder VexRiscv_test-umc22-no-adder_bit)
add_dependencies(all_qlf_k4n8_tests_adder    VexRiscv_test-umc22-adder_bit)
