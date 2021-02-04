add_file_target(FILE iir.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME iir-ql-openfpga-k4_N8-no-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES iir.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME iir-ql-openfpga-k4_N8-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES iir.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-adder
  )

add_dependencies(all_openfpga_k4_N8_tests_no_adder iir-ql-openfpga-k4_N8-no-adder_route)
add_dependencies(all_openfpga_k4_N8_tests_adder    iir-ql-openfpga-k4_N8-adder_route)
