add_file_target(FILE adder_FFs.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME adder_FFs-umc22-no-adder
  TOP adder_FFs
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES adder_FFs.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME adder_FFs-umc22-adder
  TOP adder_FFs
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES adder_FFs.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_no_adder adder_FFs-umc22-no-adder_bit)
add_dependencies(all_qlf_k4n8_tests_adder    adder_FFs-umc22-adder_bit)
