add_file_target(FILE unsigned_mult_80.v SCANNER_TYPE verilog)
add_file_target(FILE unsigned_mult_80.pcf)

add_fpga_target(
  NAME unsigned_mult_80-umc22-no-adder
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES unsigned_mult_80.v
  INPUT_IO_FILE unsigned_mult_80.pcf
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME unsigned_mult_80-umc22-adder
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES unsigned_mult_80.v
  INPUT_IO_FILE unsigned_mult_80.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_no_adder unsigned_mult_80-umc22-no-adder_route)
add_dependencies(all_qlf_k4n8_tests_adder    unsigned_mult_80-umc22-adder_route)
