add_file_target(FILE top_120_13.v SCANNER_TYPE verilog)
add_file_target(FILE top_120_13.pcf)

add_fpga_target(
  NAME top_120_13-umc22-no-adder
  TOP top_120_13
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES top_120_13.v
  INPUT_IO_FILE top_120_13.pcf
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME top_120_13-umc22-adder
  TOP top_120_13
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES top_120_13.v
  INPUT_IO_FILE top_120_13.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_no_adder top_120_13-umc22-no-adder_bit)
add_dependencies(all_qlf_k4n8_tests_adder    top_120_13-umc22-adder_bit)
