set(ADDER_M ${QL_DESIGNS_DIR}/adder_max/adder_max.v)
add_file_target(FILE ${ADDER_M} SCANNER_TYPE verilog)


add_fpga_target(
  NAME adder_max_test2-umc22-adder
  TOP adder_max
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${ADDER_M}
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_adder    adder_max_test2-umc22-adder_bit)
