set(SHIFT_REG_8 ${QL_DESIGNS_DIR}/shift_reg_8/shift_reg_8.v)
add_file_target(FILE shift_reg_8.sdc SCANNER_TYPE)

add_fpga_target(
  NAME shift_reg_8_test2-umc22-adder
  TOP shift_reg_8
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${SHIFT_REG_8}
  INPUT_SDC_FILE shift_reg_8.sdc
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_adder    shift_reg_8_test2-umc22-adder_bit)
