add_file_target(FILE io_tc1.v SCANNER_TYPE verilog)
add_file_target(FILE demux.v SCANNER_TYPE verilog)
add_file_target(FILE mux.v SCANNER_TYPE verilog)


add_fpga_target(
  NAME io_tc1-ql-openfpga-k4_N8-no-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES demux.v mux.v io_tc1.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME io_tc1-ql-openfpga-k4_N8-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES demux.v mux.v io_tc1.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-adder
  )

add_dependencies(all_openfpga_k4_N8_tests_no_adder io_tc1-ql-openfpga-k4_N8-no-adder_route)
add_dependencies(all_openfpga_k4_N8_tests_adder    io_tc1-ql-openfpga-k4_N8-adder_route)
