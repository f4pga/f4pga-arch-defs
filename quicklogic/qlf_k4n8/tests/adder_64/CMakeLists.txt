add_file_target(FILE adder_64.v SCANNER_TYPE verilog)
add_file_target(FILE adder_64.pcf)

add_fpga_target(
  NAME adder_64-umc22-no-adder
  TOP adder_64
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES adder_64.v
  INPUT_IO_FILE adder_64.pcf
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME adder_64-umc22-adder
  TOP adder_64
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES adder_64.v
  INPUT_IO_FILE adder_64.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_no_adder adder_64-umc22-no-adder_pack)
add_dependencies(all_qlf_k4n8_tests_adder    adder_64-umc22-adder_pack)
