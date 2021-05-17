set(ADDER_C ${QL_DESIGNS_DIR}/adder_columns/adder_columns.v)
add_file_target(FILE ${ADDER_C} SCANNER_TYPE verilog)

add_fpga_target(
  NAME adder_columns_test2-umc22-adder
  TOP adder_columns
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${ADDER_C}
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_adder    adder_columns_test2-umc22-adder_bit)
