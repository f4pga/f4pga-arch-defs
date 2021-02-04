add_file_target(FILE timescale.v SCANNER_TYPE verilog)
add_file_target(FILE div_su.v SCANNER_TYPE verilog)
add_file_target(FILE div_uu.v SCANNER_TYPE verilog)
add_file_target(FILE jpeg_qnr.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME jpeg_qnr-ql-openfpga-k4_N8-no-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES div_su.v div_uu.v jpeg_qnr.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME jpeg_qnr-ql-openfpga-k4_N8-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES div_su.v div_uu.v jpeg_qnr.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-adder
  )

add_dependencies(all_openfpga_k4_N8_tests_no_adder jpeg_qnr-ql-openfpga-k4_N8-no-adder_route)
add_dependencies(all_openfpga_k4_N8_tests_adder    jpeg_qnr-ql-openfpga-k4_N8-adder_route)
