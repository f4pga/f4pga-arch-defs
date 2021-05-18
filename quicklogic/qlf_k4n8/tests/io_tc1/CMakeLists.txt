add_file_target(FILE io_tc1.v SCANNER_TYPE verilog)
add_file_target(FILE demux.v SCANNER_TYPE verilog)
add_file_target(FILE mux.v SCANNER_TYPE verilog)


add_fpga_target(
  NAME io_tc1-umc22-no-adder
  TOP io_tc1
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES demux.v mux.v io_tc1.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME io_tc1-umc22-adder
  TOP io_tc1
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES demux.v mux.v io_tc1.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_no_adder io_tc1-umc22-no-adder_bit)
add_dependencies(all_qlf_k4n8_tests_adder    io_tc1-umc22-adder_bit)
