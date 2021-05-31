set(SHIFT_REG_8192 ${QL_DESIGNS_DIR}/shift_reg_8192/shift_reg_8192.v)

add_file_target(FILE ${SHIFT_REG_8192} SCANNER_TYPE verilog)

add_fpga_target(
  NAME shift_reg_8192-gf12-no-adder
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES ${SHIFT_REG_8192}
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME shift_reg_8192-gf12-adder
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES ${SHIFT_REG_8192}
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k6n10_tests_no_adder shift_reg_8192-gf12-no-adder_route)
add_dependencies(all_qlf_k6n10_tests_adder    shift_reg_8192-gf12-adder_route)
