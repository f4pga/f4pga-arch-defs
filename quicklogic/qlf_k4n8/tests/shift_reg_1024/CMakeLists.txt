add_file_target(FILE shift_reg_1024.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME shift_reg_1024-umc22-no-adder
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES shift_reg_1024.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME shift_reg_1024-umc22-adder
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES shift_reg_1024.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_no_adder shift_reg_1024-umc22-no-adder_route)
add_dependencies(all_qlf_k4n8_tests_adder    shift_reg_1024-umc22-adder_route)
